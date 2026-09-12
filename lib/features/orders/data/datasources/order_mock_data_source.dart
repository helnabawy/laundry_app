import 'dart:math';

import '../../../../core/mock/mock_database.dart';
import '../../../addresses/data/datasources/address_mock_data_source.dart';
import '../../../addresses/data/models/address_model.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../auth/data/datasources/auth_mock_data_source.dart';
import '../../domain/entities/driver_task.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/new_order_params.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_timeline_event.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
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
      'category': _catalog.categoryById(params.categoryId),
      'subService': _catalog.subServiceById(params.subServiceId),
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
    PaymentMethod method,
  ) async {
    await _db.delay();
    final row = _findOrder(orderId);
    if (row['status'] != OrderStatus.awaitingPayment) {
      _db.badRequest('Order is not awaiting payment');
    }
    final invoice = row['invoice'] as Invoice;
    row['invoice'] = Invoice(
      id: invoice.id,
      items: invoice.items,
      note: invoice.note,
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
            .where((o) => done.contains(o.status))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders
        .map(
          (o) => DriverTask(
            type: o.status == OrderStatus.pickupFailed
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
    _appendStatus(row, OrderStatus.atFacility, now.add(const Duration(seconds: 1)));
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
    String? note,
  ) async {
    await _db.delay();
    final row = _requireDriverOrder(orderId, OrderStatus.driverAssigned);
    _appendStatus(row, OrderStatus.pickupFailed, DateTime.now());
    row['failureReason'] = reason;
    row['failureNote'] = note;
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
      row['invoice'] = Invoice(
        id: invoice.id,
        items: invoice.items,
        note: invoice.note,
        paymentMethod: invoice.paymentMethod,
        paid: true,
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
    row['failureReason'] = reason;
    row['failureNote'] = note;
    return _toOrder(row);
  }

  // ---- Helpers --------------------------------------------------------

  Map<String, dynamic> _findOrder(String id) =>
      _db.findById(_table, id) ?? _db.notFound('Order not found');

  Map<String, dynamic> _requireDriverOrder(String orderId, OrderStatus expected) {
    final driverId = _db.requireUserId();
    final row = _findOrder(orderId);
    if (row['driverId'] != driverId) _db.notFound('Task not found');
    if (row['status'] != expected) {
      _db.badRequest('Task is no longer in $expected');
    }
    return row;
  }

  void _appendStatus(Map<String, dynamic> row, OrderStatus status, DateTime at) {
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
        OrderItem(name: _db.tr({'ar': 'قميص', 'en': 'Shirt'}), quantity: 2, unitPrice: 10),
      );
    }
    return Invoice(
      id: 'inv-$orderNumber',
      items: items,
      note: random.nextBool()
          ? _db.tr({
              'ar': 'بقعة على أحد القطع تحتاج معالجة خاصة',
              'en': 'A stain on one item needs special treatment',
            })
          : null,
      paymentMethod: null,
      paid: false,
    );
  }

  String? _driverName(String? driverId) {
    if (driverId == null) return null;
    final row = _db.findById(AuthMockDataSource.table, driverId);
    return row?['fullName'] as String?;
  }

  LaundryOrder _toOrder(Map<String, dynamic> row) => LaundryOrder(
    id: row['id'] as String,
    number: row['number'] as int,
    category: row['category'] as ServiceCategory,
    subService: row['subService'] as SubService,
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
  );
}
