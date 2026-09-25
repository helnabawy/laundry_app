import '../../../../core/result/result.dart';
import '../entities/invoice.dart';
import '../entities/laundry_order.dart';
import '../entities/new_order_params.dart';

abstract interface class OrderRepository {
  Future<Result<LaundryOrder>> createOrder(NewOrderParams params);
  Future<Result<List<LaundryOrder>>> getOrders();
  Future<Result<LaundryOrder>> getOrder(String id);

  /// Step 4.4: card is charged immediately (simulated); cash is collected by
  /// the driver on delivery. Processing starts only after this, so when the
  /// invoice lists stains or damage the customer must have acknowledged them
  /// ([conditionsAcknowledged]) — the backend rejects the call otherwise.
  Future<Result<LaundryOrder>> choosePaymentMethod(
    String orderId,
    PaymentMethod method, {
    required bool conditionsAcknowledged,
  });

  /// Step 5.5: stars (1–5) and an optional note, once the order is delivered.
  Future<Result<LaundryOrder>> rateOrder(
    String orderId, {
    required int stars,
    String? comment,
  });
}
