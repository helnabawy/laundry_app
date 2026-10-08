import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/exceptions.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:laundry_app/features/addresses/data/datasources/address_mock_data_source.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/payment_info.dart';

void main() {
  late MockDatabase db;
  late CatalogMockDataSource catalog;
  late OrderMockDataSource orders;

  Future<({String pickup, String delivery, String tier})> slots() async {
    final tier = (await catalog.getTiers()).first;
    final day = DateTime.now().add(const Duration(days: 1));
    final pickup = (await catalog.getPickupSlots(day, tier.id)).first;
    final delivery = (await catalog.getDeliverySlots(
      day.add(const Duration(days: 2)),
      tier.id,
      pickup.end,
    )).first;
    return (pickup: pickup.id, delivery: delivery.id, tier: tier.id);
  }

  Future<NewOrderParams> shop(PaymentMethod method, {int quantity = 2}) async {
    final product = (await catalog.getProducts()).first;
    final s = await slots();
    return NewOrderParams(
      items: [NewOrderItem(productId: product.id, quantity: quantity)],
      tierId: s.tier,
      paymentMethod: method,
      pickupSlotId: s.pickup,
      deliverySlotId: s.delivery,
      addressId: 'adr-1',
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
    db.currentUserId = MockDatabase.customerId;
  });

  test(
    'a shop card order waits for its checkout before a driver is sent',
    () async {
      final order = await orders.createOrder(await shop(PaymentMethod.card));
      expect(order.status, OrderStatus.pending);
      expect(order.invoice!.paid, isFalse);
      final payment = order.invoice!.payment!;
      expect(payment.isPending, isTrue);
      expect(payment.checkoutUrl, isNotNull);

      // Declined: still waiting, nothing dispatched.
      final declined = await orders.completeCheckout(
        payment.id,
        succeeded: false,
      );
      expect(declined.status, PaymentStatus.failed);
      expect((await orders.getOrder(order.id)).status, OrderStatus.pending);

      // Retry opens a new checkout; paying it sends the driver.
      final retried = await orders.retryPayment(order.id);
      final second = retried.invoice!.payment!;
      expect(second.id, isNot(payment.id));
      expect(second.isPending, isTrue);
      final paid = await orders.completeCheckout(second.id, succeeded: true);
      expect(paid.status, PaymentStatus.succeeded);
      expect(
        (await orders.getPayment(second.id)).status,
        PaymentStatus.succeeded,
      );

      final after = await orders.getOrder(order.id);
      expect(after.status, OrderStatus.driverAssigned);
      expect(after.invoice!.paid, isTrue);
      expect(after.invoice!.paidAt, isNotNull);
      await expectLater(
        orders.retryPayment(order.id),
        throwsA(isA<ServerException>()),
      );
    },
  );

  test('cash on delivery is dispatched straight away', () async {
    final order = await orders.createOrder(
      await shop(PaymentMethod.cashOnDelivery),
    );
    expect(order.status, OrderStatus.driverAssigned);
    expect(order.invoice!.payment, isNull);
    expect(order.invoice!.codFee, 5);
  });

  test('pay-later respects the provider minimum', () async {
    await expectLater(
      orders.createOrder(await shop(PaymentMethod.payLater, quantity: 1)),
      throwsA(isA<ServerException>()),
    );
    final options = await orders.getPaymentOptions();
    final payLater = options.firstWhere(
      (o) => o.method == PaymentMethod.payLater,
    );
    expect(payLater.minAmount, 50);
  });

  group('wizard invoice', () {
    Future<String> awaitingPayment() async {
      final s = await slots();
      final category = (await catalog.getCategories()).first;
      final sub = (await catalog.getSubServices(category.id)).first;
      final order = await orders.createOrder(
        NewOrderParams(
          lines: [NewOrderLine(categoryId: category.id, subServiceId: sub.id)],
          tierId: s.tier,
          pickupSlotId: s.pickup,
          deliverySlotId: s.delivery,
          addressId: 'adr-1',
        ),
      );
      db.currentUserId = MockDatabase.driverId;
      await orders.confirmPickup(order.id);
      db.currentUserId = MockDatabase.customerId;
      return order.id;
    }

    test('card keeps the order waiting until the checkout succeeds', () async {
      final id = await awaitingPayment();
      final chosen = await orders.choosePaymentMethod(
        id,
        PaymentMethod.card,
        conditionsAcknowledged: true,
      );
      expect(chosen.status, OrderStatus.awaitingPayment);
      expect(chosen.invoice!.awaitingOnlinePayment, isTrue);
      await orders.completeCheckout(
        chosen.invoice!.payment!.id,
        succeeded: true,
      );
      final after = await orders.getOrder(id);
      expect(after.invoice!.paid, isTrue);
      expect(
        after.timeline.map((e) => e.status),
        contains(OrderStatus.processing),
      );
    });

    test('cash on delivery adds the handling fee, like the backend', () async {
      final id = await awaitingPayment();
      final before = (await orders.getOrder(id)).invoice!.total;
      final chosen = await orders.choosePaymentMethod(
        id,
        PaymentMethod.cashOnDelivery,
        conditionsAcknowledged: true,
      );
      expect(chosen.invoice!.codFee, 5);
      expect(chosen.invoice!.total, before + 5);
      expect(
        chosen.timeline.map((e) => e.status),
        contains(OrderStatus.processing),
      );
    });
  });
}
