import '../../../../core/result/result.dart';
import '../entities/invoice.dart';
import '../entities/laundry_order.dart';
import '../entities/new_order_params.dart';

abstract interface class OrderRepository {
  Future<Result<LaundryOrder>> createOrder(NewOrderParams params);
  Future<Result<List<LaundryOrder>>> getOrders();
  Future<Result<LaundryOrder>> getOrder(String id);

  /// Step 4.4: card is charged immediately (simulated); cash is collected by
  /// the driver on delivery.
  Future<Result<LaundryOrder>> choosePaymentMethod(
    String orderId,
    PaymentMethod method,
  );
}
