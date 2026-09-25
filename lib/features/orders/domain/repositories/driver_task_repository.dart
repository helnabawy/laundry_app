import '../../../../core/result/result.dart';
import '../entities/driver_task.dart';
import '../entities/laundry_order.dart';
import '../entities/task_failure.dart';

export '../entities/task_failure.dart';

abstract interface class DriverTaskRepository {
  Future<Result<List<DriverTask>>> getTodayTasks();
  Future<Result<List<DriverTask>>> getCompletedTasks();
  Future<Result<bool>> setAvailability(bool available);

  Future<Result<LaundryOrder>> confirmPickup(String orderId);

  /// The driver couldn't collect. A photo of the stop is required; the order
  /// is cancelled and the customer is notified to book a new pickup time.
  Future<Result<LaundryOrder>> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note, {
    required bool hasPhoto,
  });

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
