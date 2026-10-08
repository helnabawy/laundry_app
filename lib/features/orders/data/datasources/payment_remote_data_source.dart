import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/payment_info.dart';

abstract interface class PaymentRemoteDataSource {
  Future<List<PaymentOption>> getPaymentOptions();
  Future<LaundryOrder> retryPayment(String orderId, {PaymentMethod? method});
  Future<PaymentInfo> getPayment(String paymentId);
}
