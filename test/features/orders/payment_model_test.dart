import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/features/orders/data/models/invoice_model.dart';
import 'package:laundry_app/features/orders/data/models/laundry_order_model.dart';
import 'package:laundry_app/features/orders/data/models/payment_info_model.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/payment_info.dart';

/// Invoice JSON as laundry_admin sends it since online payments
/// (src/server/api/serializers.ts `invoice()` / `payment()`).
Map<String, dynamic> _invoice({
  Map<String, dynamic>? payment,
  bool paid = false,
  double amountRefunded = 0,
  String method = 'card',
}) => {
  'id': 'INV-1050',
  'items': [
    {
      'name': 'Shirt',
      'quantity': 3,
      'unitPrice': 10,
      'productId': 'prod-shirt',
      'categoryId': 'cat-clothes',
    },
    {
      'name': 'Suit',
      'quantity': 1,
      'unitPrice': 45,
      'productId': 'prod-suit',
      'categoryId': 'cat-clothes',
    },
  ],
  'conditions': <dynamic>[],
  'note': null,
  'paymentMethod': method,
  'vipSurcharge': 0,
  'codFee': 0,
  'paid': paid,
  'paidAt': paid ? '2026-10-09T08:00:00.000Z' : null,
  'total': 75,
  'amountRefunded': amountRefunded,
  'payment': payment,
};

Map<String, dynamic> _payment(
  String status, {
  String? checkoutUrl,
  String method = 'card',
  String provider = 'networkIntl',
}) => {
  'id': 'pay-1',
  'status': status,
  'provider': provider,
  'method': method,
  'amount': 75,
  'reference': 'NI-abc',
  'checkoutUrl': checkoutUrl,
  'failureReason': status == 'failed' ? 'Card declined' : null,
  'paidAt': status == 'succeeded' ? '2026-10-09T08:00:00.000Z' : null,
};

void main() {
  test('an invoice from before online payments still parses', () {
    final order = LaundryOrderModel.fromJson(
      jsonDecode(File('test/fixtures/api/shop_order.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final invoice = order.invoice!;
    expect(invoice.payment, isNull);
    expect(invoice.paidAt, isNull);
    expect(invoice.amountRefunded, 0);
  });

  test('a pending card checkout is awaiting online payment', () {
    final invoice = InvoiceModel.fromJson(
      _invoice(
        payment: _payment(
          'pending',
          checkoutUrl: 'http://localhost:3100/pay/tok',
        ),
      ),
    );
    expect(invoice.total, 75);
    expect(invoice.awaitingOnlinePayment, isTrue);
    expect(invoice.payment!.isPending, isTrue);
    expect(invoice.payment!.provider, PaymentProvider.networkIntl);
    expect(invoice.payment!.checkoutUrl, 'http://localhost:3100/pay/tok');
  });

  test('pay-later through tabby, paid, then partly refunded', () {
    final invoice = InvoiceModel.fromJson(
      _invoice(
        method: 'payLater',
        paid: true,
        amountRefunded: 20,
        payment: _payment(
          'partiallyRefunded',
          method: 'payLater',
          provider: 'tabby',
        ),
      ),
    );
    expect(invoice.paymentMethod, PaymentMethod.payLater);
    expect(invoice.paymentMethod!.isOnline, isTrue);
    expect(invoice.awaitingOnlinePayment, isFalse);
    expect(invoice.paidAt, DateTime.utc(2026, 10, 9, 8));
    expect(invoice.isPartiallyRefunded, isTrue);
    expect(invoice.isRefunded, isFalse);
    expect(invoice.payment!.status.isCaptured, isTrue);
    expect(invoice.payment!.provider.brand, 'tabby');
  });

  test('a fully refunded invoice reads as refunded', () {
    final invoice = InvoiceModel.fromJson(
      _invoice(paid: true, amountRefunded: 75, payment: _payment('refunded')),
    );
    expect(invoice.isRefunded, isTrue);
  });

  test(
    'a declined attempt can be retried; unknown statuses read as failed',
    () {
      expect(
        PaymentInfoModel.fromJson(_payment('failed')).status.isUnsuccessful,
        isTrue,
      );
      expect(PaymentStatus.fromJson('chargeback'), PaymentStatus.failed);
    },
  );

  test('payment options carry pay-later limits', () {
    final option = PaymentOptionModel.fromJson({
      'method': 'payLater',
      'provider': 'tabby',
      'fee': 0,
      'installments': 4,
      'minAmount': 50,
      'maxAmount': 5000,
    });
    expect(option.accepts(49.99), isFalse);
    expect(option.accepts(50), isTrue);
    expect(option.accepts(5000.01), isFalse);
    expect(option.installments, 4);
  });
}
