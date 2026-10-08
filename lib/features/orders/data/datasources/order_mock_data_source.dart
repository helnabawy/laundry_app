import 'dart:math';

import '../../../../core/mock/mock_database.dart';
import '../../../addresses/data/datasources/address_mock_data_source.dart';
import '../../../addresses/data/models/address_model.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../auth/data/datasources/auth_mock_data_source.dart';
import '../../domain/entities/driver_task.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/item_condition.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/order_line.dart';
import '../../domain/entities/order_rating.dart';
import '../../domain/entities/new_order_params.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_timeline_event.dart';
import '../../domain/entities/payment_info.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/task_failure.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/driver_task_repository.dart';
import 'catalog_mock_data_source.dart';
import 'driver_task_remote_data_source.dart';
import 'order_remote_data_source.dart';
import 'payment_remote_data_source.dart';

/// Backs both [OrderRemoteDataSource] (customer side) and
/// [DriverTaskRemoteDataSource] (driver side): the two share one `orders`
/// table, exactly like they'll share one `Order` table in Postgres.
///
/// The facility inspection + invoicing (Admin Portal, Phase 4) and the
/// Auto-Dispatch algorithm (Phase 3) don't exist yet, so this mock collapses
/// them into instant, deterministic steps right after the driver confirms
/// pickup / the customer chooses a payment method — enough to demo the full
/// customer + driver loop end-to-end with a single seeded driver.
///
/// It also plays the payment gateway: card and pay-later open a pending
/// payment whose outcome the in-app mock checkout sheet decides
/// ([completeCheckout]), standing in for the provider's hosted page.
class OrderMockDataSource
    implements
        OrderRemoteDataSource,
        DriverTaskRemoteDataSource,
        PaymentRemoteDataSource {
  OrderMockDataSource(this._db, this._catalog);

  static const _table = 'orders';
  static const _availabilityTable = 'driver_availability';

  final MockDatabase _db;
  final CatalogMockDataSource _catalog;

  var _orderSeq = 1041;

  // ---- Customer side ------------------------------------------------------

  @override
  Future<LaundryOrder> createOrder(NewOrderParams params) async {
    await _db.delay();
    final userId = _db.requireUserId();
    final customer = _db.findById(AuthMockDataSource.table, userId)!;
    final addressRow = _db
        .table(AddressMockDataSource.table)
        .firstWhere(
          (a) => a['id'] == params.addressId,
          orElse: () => _db.notFound('Address not found'),
        );

    if (params.lines.isEmpty && params.items.isEmpty) {
      _db.badRequest('Order must have at least one line or item');
    }

    final tier = _catalog.tierById(params.tierId);
    final orderNumber = ++_orderSeq;

    List<OrderLine> lines = const [];
    Invoice? invoice;

    if (params.items.isNotEmpty) {
      // ---- Shop flow: the cart's total is fixed at checkout, before pickup.
      // Server-side is the source of truth for pricing — the client's total
      // is never trusted; every product id is resolved against the live
      // catalog and snapshotted into the order.
      if (params.paymentMethod == null) {
        _db.badRequest('Payment method is required');
      }
      final items = <OrderItem>[
        for (final item in params.items)
          () {
            if (item.quantity < 1) {
              _db.badRequest('Quantity must be at least 1');
            }
            final product = _catalog.productById(item.productId);
            return OrderItem(
              name: product.name,
              quantity: item.quantity,
              unitPrice: product.unitPrice,
              productId: product.id,
              categoryId: product.categoryId,
            );
          }(),
      ];
      final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
      final method = params.paymentMethod!;
      invoice = Invoice(
        id: 'inv-$orderNumber',
        items: items,
        vipSurcharge: tier.surchargeFor(subtotal),
        // Cash on delivery carries a flat handling fee card doesn't.
        codFee: method.codFee,
        paymentMethod: method,
        // Card / pay-later are paid on the mock checkout right after this;
        // cash is collected by the driver on delivery.
        paid: false,
      );
      if (method.isOnline) {
        _requireAccepted(method, invoice.total);
        invoice = invoice.copyWith(payment: _newPayment(method, invoice.total));
      }
    } else {
      // ---- Wizard flow: price is set later by the facility after pickup.
      lines = [
        for (final line in params.lines)
          OrderLine(
            category: _catalog.categoryById(line.categoryId),
            subService: _catalog.subServiceById(line.subServiceId),
          ),
      ];
    }

    final now = DateTime.now();
    final row = <String, dynamic>{
      'id': 'ord-$orderNumber',
      'number': orderNumber,
      'userId': userId,
      'lines': lines,
      'tier': tier,
      'pickupSlot': _catalog.slotById(params.pickupSlotId),
      'deliverySlot': _catalog.slotById(params.deliverySlotId),
      'address': AddressModel.fromJson(addressRow),
      'customerName': customer['fullName'] as String? ?? '',
      'customerPhone': customer['phone'] as String,
      'status': OrderStatus.pending,
      'driverId': null,
      'createdAt': now,
      'timeline': [OrderTimelineEvent(status: OrderStatus.pending, at: now)],
      'invoice': invoice,
    };
    // Like the backend, a shop order paid online gets no driver until the
    // money is in (see [completeCheckout]).
    if (!(invoice?.awaitingOnlinePayment ?? false)) _assignDriver(row, now);
    _db.table(_table).add(row);
    return _toOrder(row);
  }

  @override
  Future<List<LaundryOrder>> getOrders() async {
    await _db.delay();
    _dispatchWashed();
    final userId = _db.requireUserId();
    final rows = _db.table(_table).where((r) => r['userId'] == userId).toList()
      ..sort(
        (a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
      );
    return rows.map(_toOrder).toList();
  }

  @override
  Future<LaundryOrder> getOrder(String id) async {
    await _db.delay();
    _dispatchWashed();
    _db.requireUserId();
    return _toOrder(_findOrder(id));
  }

  @override
  Future<LaundryOrder> choosePaymentMethod(
    String orderId,
    PaymentMethod method, {
    required bool conditionsAcknowledged,
  }) async {
    await _db.delay();
    final row = _findOrder(orderId);
    if (row['status'] != OrderStatus.awaitingPayment) {
      _db.badRequest('Order is not awaiting payment');
    }
    final invoice = row['invoice'] as Invoice;
    if (invoice.paid) _db.badRequest('This order is already paid');
    if (invoice.hasConditions && !conditionsAcknowledged) {
      _db.badRequest('Condition report must be acknowledged first');
    }
    if (method.isOnline) {
      // The order waits for the gateway; the mock checkout decides.
      final unpaid = invoice.copyWith(paymentMethod: method, codFee: 0);
      _requireAccepted(method, unpaid.total);
      row['invoice'] = _cancelPending(unpaid)
          .copyWith(payment: _newPayment(method, unpaid.total));
      return _toOrder(row);
    }
    // Cash on delivery: the backend adds the vendor's handling fee.
    row['invoice'] = _cancelPending(
      invoice.copyWith(paymentMethod: method, codFee: method.codFee),
    );
    _startCleaning(row);
    return _toOrder(row);
  }

  // ---- Payments -------------------------------------------------------------

  /// What the seeded laundry accepts — mirrors the backend's defaults.
  static const paymentOptions = [
    PaymentOption(
      method: PaymentMethod.card,
      provider: PaymentProvider.networkIntl,
    ),
    PaymentOption(
      method: PaymentMethod.payLater,
      provider: PaymentProvider.tabby,
      minAmount: 50,
      maxAmount: 5000,
      installments: 4,
    ),
    PaymentOption(
      method: PaymentMethod.cashOnDelivery,
      provider: PaymentProvider.cash,
      fee: 5,
    ),
  ];

  @override
  Future<List<PaymentOption>> getPaymentOptions() async {
    await _db.delay();
    return paymentOptions;
  }

  @override
  Future<LaundryOrder> retryPayment(
    String orderId, {
    PaymentMethod? method,
  }) async {
    await _db.delay();
    final row = _findOrder(orderId);
    if (row['userId'] != _db.requireUserId()) _db.notFound('Order not found');
    final invoice = row['invoice'] as Invoice?;
    if (invoice == null) _db.badRequest("The invoice isn't ready yet");
    if (invoice.paid) _db.badRequest('This order is already paid');
    final current = invoice.paymentMethod;
    if (current == null || !current.isOnline) {
      _db.badRequest('Choose how to pay first');
    }
    final next = method ?? current;
    _requireAccepted(next, invoice.total);
    row['invoice'] = _cancelPending(
      invoice,
    ).copyWith(paymentMethod: next, payment: _newPayment(next, invoice.total));
    return _toOrder(row);
  }

  @override
  Future<PaymentInfo> getPayment(String paymentId) async {
    await _db.delay();
    final row = _rowWithPayment(paymentId);
    return (row['invoice'] as Invoice).payment!;
  }

  /// The mock checkout's verdict, as the provider's webhook would deliver it.
  Future<PaymentInfo> completeCheckout(
    String paymentId, {
    required bool succeeded,
  }) async {
    await _db.delay();
    final row = _rowWithPayment(paymentId);
    final invoice = row['invoice'] as Invoice;
    final payment = invoice.payment!;
    if (!payment.isPending) return payment;
    if (!succeeded) {
      final failed = payment.copyWith(
        status: PaymentStatus.failed,
        failureReason: 'Card declined by issuer (test)',
      );
      row['invoice'] = invoice.copyWith(payment: failed);
      return failed;
    }
    final now = DateTime.now();
    final paid = PaymentInfo(
      id: payment.id,
      status: PaymentStatus.succeeded,
      provider: payment.provider,
      method: payment.method,
      amount: payment.amount,
      reference: payment.reference,
      paidAt: now,
    );
    row['invoice'] = invoice.copyWith(paid: true, paidAt: now, payment: paid);
    switch (row['status']) {
      case OrderStatus.awaitingPayment:
        _startCleaning(row);
      case OrderStatus.pending:
        _assignDriver(row, now);
    }
    return paid;
  }

  PaymentInfo _newPayment(PaymentMethod method, double amount) {
    final id = 'pay-${_db.nextNumber()}';
    return PaymentInfo(
      id: id,
      status: PaymentStatus.pending,
      provider: method == PaymentMethod.payLater
          ? PaymentProvider.tabby
          : PaymentProvider.networkIntl,
      method: method,
      amount: amount,
      reference: 'MOCK-$id',
      checkoutUrl: 'mock://checkout/$id',
    );
  }

  /// A new attempt replaces any checkout still open.
  Invoice _cancelPending(Invoice invoice) {
    final payment = invoice.payment;
    if (payment == null || !payment.isPending) return invoice;
    return invoice.copyWith(
      payment: payment.copyWith(status: PaymentStatus.cancelled),
    );
  }

  void _requireAccepted(PaymentMethod method, double amount) {
    final option = paymentOptions.firstWhere((o) => o.method == method);
    if (!option.accepts(amount)) {
      _db.badRequest("This payment method isn't available for this amount");
    }
  }

  Map<String, dynamic> _rowWithPayment(String paymentId) {
    final userId = _db.requireUserId();
    return _db
        .table(_table)
        .firstWhere(
          (r) =>
              r['userId'] == userId &&
              (r['invoice'] as Invoice?)?.payment?.id == paymentId,
          orElse: () => _db.notFound('Payment not found'),
        );
  }

  /// Payment settled on a wizard order: cleaning starts, and (Phase 3/4
  /// stand-in) the delivery driver is dispatched right away so the driver
  /// app has a delivery task to demo immediately.
  void _startCleaning(Map<String, dynamic> row) {
    final now = DateTime.now();
    _appendStatus(row, OrderStatus.processing, now);
    _appendStatus(
      row,
      OrderStatus.outForDelivery,
      now.add(const Duration(seconds: 1)),
    );
  }

  /// Single seeded driver handles both legs (Phase 3 replaces this with the
  /// real auto-dispatch algorithm).
  void _assignDriver(Map<String, dynamic> row, DateTime at) {
    row['driverId'] = MockDatabase.driverId;
    _appendStatus(row, OrderStatus.driverAssigned, at);
  }

  @override
  Future<LaundryOrder> rateOrder(
    String orderId, {
    required int stars,
    String? comment,
  }) async {
    await _db.delay();
    final userId = _db.requireUserId();
    final row = _findOrder(orderId);
    if (row['userId'] != userId) _db.notFound('Order not found');
    if (row['status'] != OrderStatus.delivered) {
      _db.badRequest('Only a delivered order can be rated');
    }
    if (row['rating'] != null) _db.badRequest('Order already rated');
    if (stars < 1 || stars > OrderRating.maxStars) {
      _db.badRequest('Stars must be 1–${OrderRating.maxStars}');
    }
    row['rating'] = OrderRating(
      stars: stars,
      comment: comment,
      ratedAt: DateTime.now(),
    );
    return _toOrder(row);
  }

  // ---- Driver side ----------------------------------------------------

  @override
  Future<List<DriverTask>> getTodayTasks() async {
    await _db.delay();
    _dispatchWashed();
    final driverId = _db.requireUserId();
    return _db
        .table(_table)
        .where((r) => r['driverId'] == driverId)
        .map(_toOrder)
        .where(
          (o) =>
              o.status == OrderStatus.driverAssigned ||
              o.status == OrderStatus.outForDelivery,
        )
        .map(
          (o) => DriverTask(
            type: o.status == OrderStatus.driverAssigned
                ? TaskType.pickup
                : TaskType.delivery,
            order: o,
          ),
        )
        .toList();
  }

  @override
  Future<List<DriverTask>> getCompletedTasks() async {
    await _db.delay();
    final driverId = _db.requireUserId();
    const done = {
      OrderStatus.delivered,
      OrderStatus.pickupFailed,
      OrderStatus.deliveryFailed,
    };
    final orders =
        _db
            .table(_table)
            .where((r) => r['driverId'] == driverId)
            .map(_toOrder)
            .where((o) => done.contains(o.status) || o.pickupFailedAndCancelled)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders
        .map(
          (o) => DriverTask(
            type:
                o.status == OrderStatus.pickupFailed ||
                    o.pickupFailedAndCancelled
                ? TaskType.pickup
                : TaskType.delivery,
            order: o,
          ),
        )
        .toList();
  }

  @override
  Future<bool> setAvailability(bool available) async {
    await _db.delay();
    final driverId = _db.requireUserId();
    final rows = _db.table(_availabilityTable);
    final row = rows.firstWhere(
      (r) => r['driverId'] == driverId,
      orElse: () {
        final created = {'driverId': driverId, 'available': true};
        rows.add(created);
        return created;
      },
    );
    row['available'] = available;
    return available;
  }

  @override
  Future<LaundryOrder> confirmPickup(String orderId) async {
    await _db.delay();
    final row = _requireDriverOrder(orderId, OrderStatus.driverAssigned);
    final now = DateTime.now();
    _appendStatus(row, OrderStatus.pickedUp, now);
    if (row['invoice'] == null) {
      // Wizard flow: price isn't known yet — the facility inspects, prices,
      // and the customer pays before processing starts.
      _appendStatus(
        row,
        OrderStatus.atFacility,
        now.add(const Duration(seconds: 1)),
      );
      row['invoice'] = _generateInvoice(row['number'] as int);
      _appendStatus(
        row,
        OrderStatus.awaitingPayment,
        now.add(const Duration(seconds: 2)),
      );
    } else {
      // Shop flow: price was already fixed at checkout, so there's no
      // inspection/payment wait — the items go straight into the wash. They
      // stay there until the facility is done (see [_dispatchWashed]).
      _appendStatus(
        row,
        OrderStatus.processing,
        now.add(const Duration(seconds: 1)),
      );
    }
    return _toOrder(row);
  }

  @override
  Future<LaundryOrder> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note, {
    required String photoPath,
  }) async {
    await _db.delay();
    if (photoPath.isEmpty) {
      _db.badRequest('A photo of the pickup stop is required');
    }
    final row = _requireDriverOrder(orderId, OrderStatus.driverAssigned);
    final now = DateTime.now();
    _appendStatus(row, OrderStatus.pickupFailed, now);
    // The mock keeps the device path where the API would return a URL.
    row['failure'] = TaskFailure(
      reason: reason,
      note: note,
      photoUrl: photoPath,
    );
    // The backend cancels the order and pushes a "book a new pickup time"
    // notification; the customer re-books as a fresh order.
    _appendStatus(
      row,
      OrderStatus.cancelled,
      now.add(const Duration(seconds: 1)),
    );
    return _toOrder(row);
  }

  @override
  Future<LaundryOrder> confirmDelivery(
    String orderId, {
    required bool cashCollected,
    String? proofPhotoPath,
  }) async {
    await _db.delay();
    final row = _requireDriverOrder(orderId, OrderStatus.outForDelivery);
    final invoice = row['invoice'] as Invoice?;
    if (invoice != null &&
        invoice.paymentMethod == PaymentMethod.cashOnDelivery &&
        !invoice.paid) {
      if (!cashCollected) {
        _db.badRequest('Cash must be collected before confirming delivery');
      }
      final now = DateTime.now();
      row['invoice'] = invoice.copyWith(
        paid: true,
        paidAt: now,
        payment: PaymentInfo(
          id: 'pay-${_db.nextNumber()}',
          status: PaymentStatus.succeeded,
          provider: PaymentProvider.cash,
          method: PaymentMethod.cashOnDelivery,
          amount: invoice.total,
          paidAt: now,
        ),
      );
    }
    _appendStatus(row, OrderStatus.delivered, DateTime.now());
    return _toOrder(row);
  }

  @override
  Future<LaundryOrder> reportDeliveryFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  ) async {
    await _db.delay();
    final row = _requireDriverOrder(orderId, OrderStatus.outForDelivery);
    _appendStatus(row, OrderStatus.deliveryFailed, DateTime.now());
    row['failure'] = TaskFailure(reason: reason, note: note);
    return _toOrder(row);
  }

  // ---- Helpers --------------------------------------------------------

  /// How long a picked-up shop order stays in the wash before it is
  /// dispatched for delivery.
  static const washWindow = Duration(minutes: 1);

  /// Phase 4 stand-in: the facility operator marks the wash done and
  /// auto-dispatch hands it to a driver. With no Admin Portal yet, any order
  /// that has sat in `processing` for [washWindow] is dispatched on the next
  /// read.
  void _dispatchWashed() {
    final cutoff = DateTime.now().subtract(washWindow);
    for (final row in _db.table(_table)) {
      if (row['status'] != OrderStatus.processing) continue;
      final since = (row['timeline'] as List<OrderTimelineEvent>).last.at;
      if (since.isAfter(cutoff)) continue;
      _appendStatus(row, OrderStatus.outForDelivery, since.add(washWindow));
    }
  }

  Map<String, dynamic> _findOrder(String id) =>
      _db.findById(_table, id) ?? _db.notFound('Order not found');

  Map<String, dynamic> _requireDriverOrder(
    String orderId,
    OrderStatus expected,
  ) {
    final driverId = _db.requireUserId();
    final row = _findOrder(orderId);
    if (row['driverId'] != driverId) _db.notFound('Task not found');
    if (row['status'] != expected) {
      _db.badRequest('Task is no longer in $expected');
    }
    return row;
  }

  void _appendStatus(
    Map<String, dynamic> row,
    OrderStatus status,
    DateTime at,
  ) {
    row['status'] = status;
    (row['timeline'] as List<OrderTimelineEvent>).add(
      OrderTimelineEvent(status: status, at: at),
    );
  }

  Invoice _generateInvoice(int orderNumber) {
    final random = Random(orderNumber);
    const catalog = [
      ('قميص', 'Shirt', 10.0),
      ('بنطلون', 'Trouser', 15.0),
      ('جاكيت', 'Jacket', 25.0),
      ('فستان', 'Dress', 30.0),
    ];
    final items = <OrderItem>[];
    for (final (nameAr, nameEn, price) in catalog) {
      final qty = random.nextInt(5);
      if (qty == 0) continue;
      items.add(
        OrderItem(
          name: _db.tr({'ar': nameAr, 'en': nameEn}),
          quantity: qty,
          unitPrice: price,
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        OrderItem(
          name: _db.tr({'ar': 'قميص', 'en': 'Shirt'}),
          quantity: 2,
          unitPrice: 10,
        ),
      );
    }
    return Invoice(
      id: 'inv-$orderNumber',
      items: items,
      conditions: _sortingFindings(random, items),
      paymentMethod: null,
      paid: false,
    );
  }

  /// What sorting turned up (step 4.2). Roughly half of all invoices carry
  /// at least one finding so both paths of the invoice can be demoed.
  List<ItemCondition> _sortingFindings(Random random, List<OrderItem> items) {
    if (random.nextBool()) return const [];
    const findings = [
      (
        ConditionKind.stain,
        {
          'ar': 'بقعة قديمة على الياقة، قد لا تزول بالكامل',
          'en': 'Set-in stain on the collar; it may not come out fully',
        },
      ),
      (
        ConditionKind.damage,
        {
          'ar': 'زر مفقود قبل الاستلام',
          'en': 'A button was already missing on arrival',
        },
      ),
      (
        ConditionKind.stain,
        {
          'ar': 'بقعة زيت صغيرة على الأمام',
          'en': 'Small oil stain on the front',
        },
      ),
    ];
    final count = 1 + random.nextInt(2);
    return [
      for (var i = 0; i < count; i++)
        ItemCondition(
          itemName: items[random.nextInt(items.length)].name,
          kind: findings[i].$1,
          note: _db.tr(findings[i].$2),
        ),
    ];
  }

  String? _driverName(String? driverId) {
    if (driverId == null) return null;
    final row = _db.findById(AuthMockDataSource.table, driverId);
    return row?['fullName'] as String?;
  }

  /// Seeded rows still carry the single `category` / `subService` pair.
  List<OrderLine> _rowLines(Map<String, dynamic> row) =>
      (row['lines'] as List<OrderLine>?) ??
      [
        OrderLine(
          category: row['category'] as ServiceCategory,
          subService: row['subService'] as SubService,
        ),
      ];

  LaundryOrder _toOrder(Map<String, dynamic> row) => LaundryOrder(
    id: row['id'] as String,
    number: row['number'] as int,
    lines: _rowLines(row),
    tier: row['tier'] as ServiceTier,
    pickupSlot: row['pickupSlot'] as TimeSlot,
    deliverySlot: row['deliverySlot'] as TimeSlot,
    address: row['address'] as Address,
    customerName: row['customerName'] as String,
    customerPhone: row['customerPhone'] as String,
    status: row['status'] as OrderStatus,
    createdAt: row['createdAt'] as DateTime,
    timeline: List<OrderTimelineEvent>.from(row['timeline'] as List),
    driverName: _driverName(row['driverId'] as String?),
    invoice: row['invoice'] as Invoice?,
    failure: row['failure'] as TaskFailure?,
    rating: row['rating'] as OrderRating?,
  );
}
