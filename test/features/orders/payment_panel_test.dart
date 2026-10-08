import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/di/injection.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:laundry_app/features/addresses/data/datasources/address_mock_data_source.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/repositories/payment_repository_impl.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/payment_info.dart';
import 'package:laundry_app/features/orders/domain/usecases/payment_usecases.dart';
import 'package:laundry_app/features/orders/presentation/cubit/payment_status_cubit.dart';
import 'package:laundry_app/features/orders/presentation/utils/payment_launcher.dart';
import 'package:laundry_app/features/orders/presentation/widgets/payment_panel.dart';

import '../../helpers/pump_app.dart';

void main() {
  late MockDatabase db;
  late OrderMockDataSource orders;

  setUp(() async {
    await sl.reset();
    db = MockDatabase(languageCode: () => 'en', latency: Duration.zero);
    AddressMockDataSource.seed(db);
    db.table(AuthMockDataSource.table).add({
      'id': MockDatabase.customerId,
      'phone': MockDatabase.customerPhone,
      'fullName': 'Customer',
      'role': 'customer',
    });
    db.currentUserId = MockDatabase.customerId;
    final catalog = CatalogMockDataSource(db);
    orders = OrderMockDataSource(db, catalog);
    final status = GetPaymentStatus(PaymentRepositoryImpl(orders));
    sl
      ..registerFactory(
        () => PaymentStatusCubit(status, backoff: const [Duration.zero]),
      )
      ..registerSingleton<PaymentLauncher>(MockPaymentLauncher(orders));
  });

  tearDown(sl.reset);

  Future<PaymentInfo> pendingCardPayment() async {
    final product = (await CatalogMockDataSource(db).getProducts()).first;
    final catalog = CatalogMockDataSource(db);
    final tier = (await catalog.getTiers()).first;
    final day = DateTime.now().add(const Duration(days: 1));
    final pickup = (await catalog.getPickupSlots(day, tier.id)).first;
    final delivery = (await catalog.getDeliverySlots(
      day.add(const Duration(days: 2)),
      tier.id,
      pickup.end,
    )).first;
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
    return order.invoice!.payment!;
  }

  testWidgets('finishing the mock checkout settles the payment', (
    tester,
  ) async {
    final payment = await tester.runAsync(pendingCardPayment);
    PaymentInfo? settled;
    await tester.pumpPage(
      Scaffold(
        body: ListView(
          children: [
            PaymentPanel(payment: payment, onSettled: (p) => settled = p),
          ],
        ),
      ),
    );
    expect(find.text('WAITING FOR PAYMENT'), findsOneWidget);

    await tester.tap(find.text('Complete payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Pay '));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(settled?.status, PaymentStatus.succeeded);
    expect(find.text('PAYMENT SUCCESSFUL'), findsOneWidget);
  });

  testWidgets('a declined checkout offers a retry', (tester) async {
    final payment = await tester.runAsync(pendingCardPayment);
    final declined = await tester.runAsync(
      () => orders.completeCheckout(payment!.id, succeeded: false),
    );
    var retried = false;
    await tester.pumpPage(
      Scaffold(
        body: ListView(
          children: [
            PaymentPanel(
              payment: declined,
              onSettled: (_) {},
              onRetry: () async {
                retried = true;
                return null;
              },
            ),
          ],
        ),
      ),
    );
    expect(find.text("PAYMENT DIDN'T GO THROUGH"), findsOneWidget);
    await tester.tap(find.text('Try payment again'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });
}
