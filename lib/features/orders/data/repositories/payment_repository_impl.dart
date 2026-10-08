import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/payment_info.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Future<Result<List<PaymentOption>>> getPaymentOptions() =>
      guard(_remote.getPaymentOptions);

  @override
  Future<Result<LaundryOrder>> retryPayment(
    String orderId, {
    PaymentMethod? method,
  }) => guard(() => _remote.retryPayment(orderId, method: method));

  @override
  Future<Result<PaymentInfo>> getPayment(String paymentId) =>
      guard(() => _remote.getPayment(paymentId));
}
