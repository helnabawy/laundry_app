import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/driver_task.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/repositories/driver_task_repository.dart';
import '../models/driver_task_model.dart';
import '../models/laundry_order_model.dart';
import 'driver_task_remote_data_source.dart';

class DriverTaskApiDataSource implements DriverTaskRemoteDataSource {
  const DriverTaskApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<DriverTask>> getTodayTasks() async {
    final json =
        await _api.get(ApiEndpoints.driverTasks, query: {'status': 'today'})
            as List<dynamic>;
    return json.cast<Map<String, dynamic>>().map(DriverTaskModel.fromJson).toList();
  }

  @override
  Future<List<DriverTask>> getCompletedTasks() async {
    final json =
        await _api.get(ApiEndpoints.driverTasks, query: {'status': 'completed'})
            as List<dynamic>;
    return json.cast<Map<String, dynamic>>().map(DriverTaskModel.fromJson).toList();
  }

  @override
  Future<bool> setAvailability(bool available) async {
    await _api.post(ApiEndpoints.driverAvailability, data: {'available': available});
    return available;
  }

  @override
  Future<LaundryOrder> confirmPickup(String orderId) => _action(orderId, 'confirm-pickup');

  @override
  Future<LaundryOrder> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  ) => _action(
    orderId,
    'report-pickup-failed',
    data: {'reason': reason.name, 'note': note},
  );

  @override
  Future<LaundryOrder> confirmDelivery(
    String orderId, {
    required bool cashCollected,
    bool hasProofPhoto = false,
  }) => _action(
    orderId,
    'confirm-delivery',
    data: {'cashCollected': cashCollected, 'hasProofPhoto': hasProofPhoto},
  );

  @override
  Future<LaundryOrder> reportDeliveryFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  ) => _action(
    orderId,
    'report-delivery-failed',
    data: {'reason': reason.name, 'note': note},
  );

  Future<LaundryOrder> _action(
    String orderId,
    String action, {
    Object? data,
  }) async {
    final json = await _api.post(
      ApiEndpoints.driverTaskAction(orderId, action),
      data: data,
    );
    return LaundryOrderModel.fromJson(json as Map<String, dynamic>);
  }
}
