import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/new_order_params.dart';

abstract interface class OrderRemoteDataSource {
  Future<LaundryOrder> createOrder(NewOrderParams params);
  Future<List<LaundryOrder>> getOrders();
  Future<LaundryOrder> getOrder(String id);
  Future<LaundryOrder> choosePaymentMethod(String orderId, PaymentMethod method);
}
