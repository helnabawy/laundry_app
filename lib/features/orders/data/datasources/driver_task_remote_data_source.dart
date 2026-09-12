import '../../domain/entities/driver_task.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/repositories/driver_task_repository.dart';

abstract interface class DriverTaskRemoteDataSource {
  Future<List<DriverTask>> getTodayTasks();
  Future<List<DriverTask>> getCompletedTasks();
  Future<bool> setAvailability(bool available);

  Future<LaundryOrder> confirmPickup(String orderId);
  Future<LaundryOrder> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  );

  Future<LaundryOrder> confirmDelivery(
    String orderId, {
    required bool cashCollected,
    bool hasProofPhoto = false,
  });
  Future<LaundryOrder> reportDeliveryFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  );
}
