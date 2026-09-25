import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice.dart';
import '../entities/laundry_order.dart';
import '../entities/new_order_params.dart';
import '../repositories/order_repository.dart';

class CreateOrder implements UseCase<LaundryOrder, NewOrderParams> {
  const CreateOrder(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(NewOrderParams params) =>
      _repo.createOrder(params);
}

class GetOrders implements UseCase<List<LaundryOrder>, NoParams> {
  const GetOrders(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<List<LaundryOrder>>> call([
    NoParams params = const NoParams(),
  ]) => _repo.getOrders();
}

class GetOrder implements UseCase<LaundryOrder, String> {
  const GetOrder(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(String id) => _repo.getOrder(id);
}

typedef ChoosePaymentParams = ({
  String orderId,
  PaymentMethod method,
  bool conditionsAcknowledged,
});

class ChoosePaymentMethod
    implements UseCase<LaundryOrder, ChoosePaymentParams> {
  const ChoosePaymentMethod(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(ChoosePaymentParams params) =>
      _repo.choosePaymentMethod(
        params.orderId,
        params.method,
        conditionsAcknowledged: params.conditionsAcknowledged,
      );
}

class RateOrder
    implements
        UseCase<LaundryOrder, ({String orderId, int stars, String? comment})> {
  const RateOrder(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(
    ({String orderId, int stars, String? comment}) params,
  ) => _repo.rateOrder(
    params.orderId,
    stars: params.stars,
    comment: params.comment,
  );
}
