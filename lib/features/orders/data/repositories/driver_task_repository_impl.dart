import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/driver_task.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/repositories/driver_task_repository.dart';
import '../datasources/driver_task_remote_data_source.dart';

class DriverTaskRepositoryImpl implements DriverTaskRepository {
  const DriverTaskRepositoryImpl(this._remote);

  final DriverTaskRemoteDataSource _remote;

  @override
  Future<Result<List<DriverTask>>> getTodayTasks() => guard(_remote.getTodayTasks);

  @override
  Future<Result<List<DriverTask>>> getCompletedTasks() =>
      guard(_remote.getCompletedTasks);

  @override
  Future<Result<bool>> setAvailability(bool available) =>
      guard(() => _remote.setAvailability(available));

  @override
  Future<Result<LaundryOrder>> confirmPickup(String orderId) =>
      guard(() => _remote.confirmPickup(orderId));

  @override
  Future<Result<LaundryOrder>> reportPickupFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  ) => guard(() => _remote.reportPickupFailed(orderId, reason, note));

  @override
  Future<Result<LaundryOrder>> confirmDelivery(
    String orderId, {
    required bool cashCollected,
    bool hasProofPhoto = false,
  }) => guard(
    () => _remote.confirmDelivery(
      orderId,
      cashCollected: cashCollected,
      hasProofPhoto: hasProofPhoto,
    ),
  );

  @override
  Future<Result<LaundryOrder>> reportDeliveryFailed(
    String orderId,
    TaskFailureReason reason,
    String? note,
  ) => guard(() => _remote.reportDeliveryFailed(orderId, reason, note));
}
