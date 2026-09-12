import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/new_order_params.dart';
import '../models/laundry_order_model.dart';
import 'order_remote_data_source.dart';

class OrderApiDataSource implements OrderRemoteDataSource {
  const OrderApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<LaundryOrder> createOrder(NewOrderParams params) async {
    final json = await _api.post(
      ApiEndpoints.orders,
      data: {
        'categoryId': params.categoryId,
        'subServiceId': params.subServiceId,
        'tierId': params.tierId,
        'pickupSlotId': params.pickupSlotId,
        'deliverySlotId': params.deliverySlotId,
        'addressId': params.addressId,
      },
    );
    return LaundryOrderModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<LaundryOrder>> getOrders() async {
    final json = await _api.get(ApiEndpoints.orders) as List<dynamic>;
    return json.cast<Map<String, dynamic>>().map(LaundryOrderModel.fromJson).toList();
  }

  @override
  Future<LaundryOrder> getOrder(String id) async {
    final json = await _api.get(ApiEndpoints.order(id));
    return LaundryOrderModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<LaundryOrder> choosePaymentMethod(
    String orderId,
    PaymentMethod method,
  ) async {
    final json = await _api.post(
      ApiEndpoints.orderPaymentMethod(orderId),
      data: {'method': method.name},
    );
    return LaundryOrderModel.fromJson(json as Map<String, dynamic>);
  }
}
