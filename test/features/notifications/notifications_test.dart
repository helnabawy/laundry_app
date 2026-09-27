import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:laundry_app/features/addresses/data/datasources/address_mock_data_source.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:laundry_app/features/notifications/data/datasources/notification_mock_data_source.dart';
import 'package:laundry_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:laundry_app/features/notifications/domain/entities/app_notification.dart';
import 'package:laundry_app/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:laundry_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/task_failure.dart';

void main() {
  late MockDatabase db;
  late OrderMockDataSource orders;
  late NotificationMockDataSource inbox;

  Future<String> placeOrder(CatalogMockDataSource catalog) async {
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
    return order.id;
  }

  List<NotificationKind> kinds(List<AppNotification> list) =>
      list.map((n) => n.kind).toList();

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
    orders = OrderMockDataSource(db, CatalogMockDataSource(db));
    inbox = NotificationMockDataSource(db);
  });

  test('each role hears about its own side of the order', () async {
    final orderId = await placeOrder(CatalogMockDataSource(db));
    db.currentUserId = MockDatabase.driverId;
    await orders.confirmPickup(orderId);

    db.currentUserId = MockDatabase.customerId;
    // Newest first; `atFacility` is not announced.
    expect(kinds(await inbox.getNotifications()), [
      NotificationKind.invoiceReady,
      NotificationKind.pickedUp,
      NotificationKind.driverAssigned,
    ]);

    db.currentUserId = MockDatabase.driverId;
    expect(kinds(await inbox.getNotifications()), [NotificationKind.newPickup]);
  });

  test('a failed pickup is announced once, not again as a cancel', () async {
    final orderId = await placeOrder(CatalogMockDataSource(db));
    db.currentUserId = MockDatabase.driverId;
    await orders.reportPickupFailed(
      orderId,
      TaskFailureReason.customerAbsent,
      null,
      photoPath: '/tmp/stop.jpg',
    );

    db.currentUserId = MockDatabase.customerId;
    expect(kinds(await inbox.getNotifications()), [
      NotificationKind.pickupFailed,
      NotificationKind.driverAssigned,
    ]);
  });

  test(
    'opening the inbox reads it, but this visit still shows what was new',
    () async {
      await placeOrder(CatalogMockDataSource(db));
      final repo = NotificationRepositoryImpl(inbox);
      final cubit = NotificationsCubit(
        GetNotifications(repo),
        MarkAllNotificationsRead(repo),
      );
      addTearDown(cubit.close);

      await cubit.openInbox();
      expect(cubit.state.unreadCount, 1);

      // The bell re-reads on the way back and finds nothing new.
      await cubit.load();
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.notifications.single.read, isTrue);
    },
  );

  test('an unknown kind from a newer backend reads as a generic update', () {
    expect(NotificationKind.fromJson('refundIssued'), NotificationKind.update);
  });
}
