import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/payment_info.dart';
import '../models/laundry_order_model.dart';
import '../models/payment_info_model.dart';
import 'payment_remote_data_source.dart';

class PaymentApiDataSource implements PaymentRemoteDataSource {
  const PaymentApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<PaymentOption>> getPaymentOptions() async {
    final json = await _api.get(ApiEndpoints.paymentOptions) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(PaymentOptionModel.fromJson)
        .toList();
  }

  @override
  Future<LaundryOrder> retryPayment(
    String orderId, {
    PaymentMethod? method,
  }) async {
    final json = await _api.post(
      ApiEndpoints.orderPayments(orderId),
      data: {'method': ?method?.name},
    );
    return LaundryOrderModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<PaymentInfo> getPayment(String paymentId) async {
    final json = await _api.get(ApiEndpoints.payment(paymentId));
    return PaymentInfoModel.fromJson(json as Map<String, dynamic>);
  }
}
