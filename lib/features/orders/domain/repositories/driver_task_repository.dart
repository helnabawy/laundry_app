import '../../../../core/result/result.dart';
import '../entities/driver_task.dart';
import '../entities/laundry_order.dart';

enum TaskFailureReason {
  customerAbsent,
  wrongAddress,
  customerRescheduled,
  other;

  static TaskFailureReason fromJson(String value) =>
      TaskFailureReason.values.firstWhere((r) => r.name == value);
}

abstract interface class DriverTaskRepository {
  Future<Result<List<DriverTask>>> getTodayTasks();
  Future<Result<List<DriverTask>>> getCompletedTasks();
  Future<Result<bool>> setAvailability(bool available);

  Future<Result<LaundryOrder>> confirmPickup(String orderId);
  Future<Result<LaundryOrder>> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  );

  Future<Result<LaundryOrder>> confirmDelivery(
    String orderId, {
    required bool cashCollected,
    bool hasProofPhoto,
  });
  Future<Result<LaundryOrder>> reportDeliveryFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  );
}
