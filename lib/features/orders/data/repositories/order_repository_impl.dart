import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/new_order_params.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<Result<LaundryOrder>> createOrder(NewOrderParams params) =>
      guard(() => _remote.createOrder(params));

  @override
  Future<Result<List<LaundryOrder>>> getOrders() => guard(_remote.getOrders);

  @override
  Future<Result<LaundryOrder>> getOrder(String id) =>
      guard(() => _remote.getOrder(id));

  @override
  Future<Result<LaundryOrder>> choosePaymentMethod(
    String orderId,
    PaymentMethod method, {
    required bool conditionsAcknowledged,
  }) => guard(
    () => _remote.choosePaymentMethod(
      orderId,
      method,
      conditionsAcknowledged: conditionsAcknowledged,
    ),
  );

  @override
  Future<Result<LaundryOrder>> rateOrder(
    String orderId, {
    required int stars,
    String? comment,
  }) => guard(() => _remote.rateOrder(orderId, stars: stars, comment: comment));
}
