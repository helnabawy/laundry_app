import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice.dart';
import '../entities/laundry_order.dart';
import '../entities/payment_info.dart';
import '../repositories/payment_repository.dart';

class GetPaymentOptions implements UseCase<List<PaymentOption>, NoParams> {
  const GetPaymentOptions(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Result<List<PaymentOption>>> call([
    NoParams params = const NoParams(),
  ]) => _repo.getPaymentOptions();
}

typedef RetryPaymentParams = ({String orderId, PaymentMethod? method});

class RetryPayment implements UseCase<LaundryOrder, RetryPaymentParams> {
  const RetryPayment(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(RetryPaymentParams params) =>
      _repo.retryPayment(params.orderId, method: params.method);
}

class GetPaymentStatus implements UseCase<PaymentInfo, String> {
  const GetPaymentStatus(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Result<PaymentInfo>> call(String paymentId) =>
      _repo.getPayment(paymentId);
}
