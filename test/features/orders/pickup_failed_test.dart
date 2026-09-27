import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/exceptions.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:laundry_app/features/addresses/data/datasources/address_mock_data_source.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/task_failure.dart';
import 'package:laundry_app/features/orders/presentation/cubit/orders_cubit.dart';

void main() {
  late MockDatabase db;
  late OrderMockDataSource orders;
  late String orderId;

  setUp(() async {
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
    final catalog = CatalogMockDataSource(db);
    orders = OrderMockDataSource(db, catalog);

    final category = (await catalog.getCategories()).first;
    final subService = (await catalog.getSubServices(category.id)).first;
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
        lines: [
          NewOrderLine(categoryId: category.id, subServiceId: subService.id),
        ],
        tierId: tier.id,
        pickupSlotId: pickup.id,
        deliverySlotId: delivery.id,
        addressId: 'adr-1',
      ),
    );
    orderId = order.id;
    db.currentUserId = MockDatabase.driverId;
  });

  test('a failed pickup cannot be reported without a photo', () async {
    await expectLater(
      orders.reportPickupFailed(
        orderId,
        TaskFailureReason.customerAbsent,
        null,
        photoPath: '',
      ),
      throwsA(isA<ServerException>()),
    );
    expect((await orders.getTodayTasks()).single.orderId, orderId);
  });

  test('a failed pickup cancels the order and keeps the report', () async {
    final order = await orders.reportPickupFailed(
      orderId,
      TaskFailureReason.customerAbsent,
      'No answer at the door',
      photoPath: '/tmp/stop.jpg',
    );

    expect(order.status, OrderStatus.cancelled);
    expect(order.pickupFailedAndCancelled, isTrue);
    expect(
      order.failure,
      const TaskFailure(
        reason: TaskFailureReason.customerAbsent,
        note: 'No answer at the door',
        photoUrl: '/tmp/stop.jpg',
      ),
    );

    // Gone from the driver's list, kept in their history.
    expect(await orders.getTodayTasks(), isEmpty);
    expect((await orders.getCompletedTasks()).single.orderId, orderId);

    // The customer is asked to rebook until they place a new order.
    db.currentUserId = MockDatabase.customerId;
    final state = OrdersState(orders: await orders.getOrders());
    expect(state.failedPickupToReschedule?.id, orderId);
    expect(state.current, isNull);
  });
}
