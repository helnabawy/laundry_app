import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:laundry_app/features/addresses/data/datasources/address_mock_data_source.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:laundry_app/features/orders/domain/entities/driver_task.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/order_timeline_event.dart';

void main() {
  late MockDatabase db;
  late CatalogMockDataSource catalog;
  late OrderMockDataSource orders;

  /// A shop order: priced and paid for at checkout, before pickup.
  Future<String> placeShopOrder() async {
    final product = (await catalog.getProducts()).first;
    final tier = (await catalog.getTiers()).first;
    final day = DateTime.now().add(const Duration(days: 1));
    final pickup = (await catalog.getPickupSlots(day, tier.id)).first;
    final delivery = (await catalog.getDeliverySlots(
      day.add(const Duration(days: 2)),
      tier.id,
      pickup.end,
    )).first;
    db.currentUserId = MockDatabase.customerId;
    final order = await orders.createOrder(
      NewOrderParams(
        items: [NewOrderItem(productId: product.id, quantity: 2)],
        tierId: tier.id,
        paymentMethod: PaymentMethod.card,
        pickupSlotId: pickup.id,
        deliverySlotId: delivery.id,
        addressId: 'adr-1',
      ),
    );
    // Card: the driver is only assigned once the checkout succeeds.
    await orders.completeCheckout(order.invoice!.payment!.id, succeeded: true);
    return order.id;
  }

  /// Moves the order's latest event back in time, as if it had been
  /// sitting in that status for [ago].
  void backdateLastEvent(String orderId, Duration ago) {
    final timeline =
        db.findById('orders', orderId)!['timeline'] as List<OrderTimelineEvent>;
    final last = timeline.removeLast();
    timeline.add(
      OrderTimelineEvent(status: last.status, at: last.at.subtract(ago)),
    );
  }

  setUp(() {
    db = MockDatabase(languageCode: () => 'en', latency: Duration.zero);
    AddressMockDataSource.seed(db);
    db.table(AuthMockDataSource.table).addAll([
      {
        'id': MockDatabase.customerId,
        'phone': MockDatabase.customerPhone,
        'fullName': 'Customer',
        'role': 'customer',
      },
      {
        'id': MockDatabase.driverId,
        'phone': MockDatabase.driverPhone,
        'fullName': 'Driver',
        'role': 'driver',
      },
    ]);
    catalog = CatalogMockDataSource(db);
    orders = OrderMockDataSource(db, catalog);
  });

  test(
    'a picked-up shop order goes into the wash, not out for delivery',
    () async {
      final orderId = await placeShopOrder();
      db.currentUserId = MockDatabase.driverId;

      final picked = await orders.confirmPickup(orderId);

      expect(picked.status, OrderStatus.processing);
      expect(await orders.getTodayTasks(), isEmpty);
    },
  );

  test('once the wash window passes it becomes a delivery task', () async {
    final orderId = await placeShopOrder();
    db.currentUserId = MockDatabase.driverId;
    await orders.confirmPickup(orderId);

    backdateLastEvent(
      orderId,
      OrderMockDataSource.washWindow + const Duration(seconds: 5),
    );
    final tasks = await orders.getTodayTasks();

    expect(tasks, hasLength(1));
    expect(tasks.single.type, TaskType.delivery);
    expect(tasks.single.order.status, OrderStatus.outForDelivery);
  });
}
