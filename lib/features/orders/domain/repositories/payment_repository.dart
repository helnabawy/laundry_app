import '../../../../core/result/result.dart';
import '../entities/invoice.dart';
import '../entities/laundry_order.dart';
import '../entities/payment_info.dart';

/// Online payments: what the laundry accepts, and the hosted-checkout
/// attempts on an order. Choosing how to pay a wizard invoice stays on
/// [OrderRepository.choosePaymentMethod].
abstract interface class PaymentRepository {
  Future<Result<List<PaymentOption>>> getPaymentOptions();

  /// Opens a new checkout for an order whose online payment was declined,
  /// cancelled or expired, optionally switching between card and pay-later.
  Future<Result<LaundryOrder>> retryPayment(
    String orderId, {
    PaymentMethod? method,
  });

  Future<Result<PaymentInfo>> getPayment(String paymentId);
}
