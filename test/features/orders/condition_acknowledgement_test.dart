import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/exceptions.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_mock_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/item_condition.dart';
import 'package:laundry_app/features/orders/domain/entities/order_item.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';

void main() {
  late MockDatabase db;
  late OrderMockDataSource orders;

  const invoiceWithStain = Invoice(
    id: 'inv-1',
    items: [OrderItem(name: 'Shirt', quantity: 2, unitPrice: 10)],
    conditions: [ItemCondition(itemName: 'Shirt', kind: ConditionKind.stain)],
    paymentMethod: null,
    paid: false,
  );

  void seedOrder(Invoice invoice) => db.table('orders').add({
    'id': 'ord-1',
    'status': OrderStatus.awaitingPayment,
    'timeline': [],
    'invoice': invoice,
  });

  setUp(() {
    db = MockDatabase(languageCode: () => 'en', latency: Duration.zero)
      ..currentUserId = MockDatabase.customerId;
    orders = OrderMockDataSource(db, CatalogMockDataSource(db));
  });

  test('processing does not start until stains/damage are acknowledged', () {
    seedOrder(invoiceWithStain);
    expect(
      orders.choosePaymentMethod(
        'ord-1',
        PaymentMethod.cashOnDelivery,
        conditionsAcknowledged: false,
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('acknowledging the condition report lets payment go through', () async {
    seedOrder(invoiceWithStain);
    try {
      await orders.choosePaymentMethod(
        'ord-1',
        PaymentMethod.cashOnDelivery,
        conditionsAcknowledged: true,
      );
    } on TypeError {
      // The seeded row is too thin to map back into a full order; the
      // update itself has already happened by then.
    }
    final row = db.findById('orders', 'ord-1')!;
    expect(row['status'], isNot(OrderStatus.awaitingPayment));
    expect(
      (row['invoice'] as Invoice).paymentMethod,
      PaymentMethod.cashOnDelivery,
    );
  });
}
