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
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/task_failure.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/driver_task_repository.dart';
import 'catalog_mock_data_source.dart';
import 'driver_task_remote_data_source.dart';
import 'order_remote_data_source.dart';

/// Backs both [OrderRemoteDataSource] (customer side) and
/// [DriverTaskRemoteDataSource] (driver side): the two share one `orders`
/// table, exactly like they'll share one `Order` table in Postgres.
///
/// The facility inspection + invoicing (Admin Portal, Phase 4) and the
/// Auto-Dispatch algorithm (Phase 3) don't exist yet, so this mock collapses
/// them into instant, deterministic steps right after the driver confirms
/// pickup / the customer chooses a payment method — enough to demo the full
/// customer + driver loop end-to-end with a single seeded driver.
class OrderMockDataSource
    implements OrderRemoteDataSource, DriverTaskRemoteDataSource {
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

    final now = DateTime.now();
    final row = <String, dynamic>{
      'id': 'ord-${++_orderSeq}',
      'number': _orderSeq,
      'userId': userId,
      'lines': [
        for (final line in params.lines)
          OrderLine(
            category: _catalog.categoryById(line.categoryId),
            subService: _catalog.subServiceById(line.subServiceId),
          ),
      ],
      'tier': _catalog.tierById(params.tierId),
      'pickupSlot': _catalog.slotById(params.pickupSlotId),
      'deliverySlot': _catalog.slotById(params.deliverySlotId),
      'address': AddressModel.fromJson(addressRow),
      'customerName': customer['fullName'] as String? ?? '',
      'customerPhone': customer['phone'] as String,
      'status': OrderStatus.driverAssigned,
      // Single seeded driver handles both legs (Phase 3 replaces this with
      // the real auto-dispatch algorithm).
      'driverId': MockDatabase.driverId,
      'createdAt': now,
      'timeline': [
        OrderTimelineEvent(status: OrderStatus.pending, at: now),
        OrderTimelineEvent(status: OrderStatus.driverAssigned, at: now),
      ],
      'invoice': null,
    };
    _db.table(_table).add(row);
    return _toOrder(row);
  }

  @override
  Future<List<LaundryOrder>> getOrders() async {
    await _db.delay();
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
    if (invoice.hasConditions && !conditionsAcknowledged) {
      _db.badRequest('Condition report must be acknowledged first');
    }
    row['invoice'] = invoice.copyWith(
      paymentMethod: method,
      // Card payment is simulated as an instant successful charge; cash is
      // collected by the driver on delivery.
      paid: method == PaymentMethod.card,
    );
    final now = DateTime.now();
    _appendStatus(row, OrderStatus.processing, now);
    // Phase 3/4 stand-in: auto-dispatch the delivery driver right away so
    // the driver app has a delivery task to demo immediately.
    _appendStatus(
      row,
      OrderStatus.outForDelivery,
      now.add(const Duration(seconds: 1)),
    );
    return _toOrder(row);
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
    return _toOrder(row);
  }

  @override
  Future<LaundryOrder> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note, {
    required bool hasPhoto,
  }) async {
    await _db.delay();
    if (!hasPhoto) _db.badRequest('A photo of the pickup stop is required');
    final row = _requireDriverOrder(orderId, OrderStatus.driverAssigned);
    final now = DateTime.now();
    _appendStatus(row, OrderStatus.pickupFailed, now);
    row['failure'] = TaskFailure(reason: reason, note: note, hasPhoto: true);
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
    bool hasProofPhoto = false,
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
      row['invoice'] = invoice.copyWith(paid: true);
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
