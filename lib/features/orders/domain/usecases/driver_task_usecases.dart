import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/driver_task.dart';
import '../entities/laundry_order.dart';
import '../repositories/driver_task_repository.dart';

class GetTodayTasks implements UseCase<List<DriverTask>, NoParams> {
  const GetTodayTasks(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<List<DriverTask>>> call([NoParams params = const NoParams()]) =>
      _repo.getTodayTasks();
}

class GetCompletedTasks implements UseCase<List<DriverTask>, NoParams> {
  const GetCompletedTasks(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<List<DriverTask>>> call([NoParams params = const NoParams()]) =>
      _repo.getCompletedTasks();
}

class SetAvailability implements UseCase<bool, bool> {
  const SetAvailability(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<bool>> call(bool available) => _repo.setAvailability(available);
}

class ConfirmPickup implements UseCase<LaundryOrder, String> {
  const ConfirmPickup(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(String orderId) =>
      _repo.confirmPickup(orderId);
}

class ReportPickupFailed
    implements
        UseCase<
          LaundryOrder,
          ({
            String orderId,
            TaskFailureReason reason,
            String? note,
            String photoPath,
          })
        > {
  const ReportPickupFailed(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(
    ({String orderId, TaskFailureReason reason, String? note, String photoPath})
    params,
  ) => _repo.reportPickupFailed(
    params.orderId,
    params.reason,
    params.note,
    photoPath: params.photoPath,
  );
}

class ConfirmDelivery
    implements
        UseCase<
          LaundryOrder,
          ({String orderId, bool cashCollected, String? proofPhotoPath})
        > {
  const ConfirmDelivery(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(
    ({String orderId, bool cashCollected, String? proofPhotoPath}) params,
  ) => _repo.confirmDelivery(
    params.orderId,
    cashCollected: params.cashCollected,
    proofPhotoPath: params.proofPhotoPath,
  );
}

class ReportDeliveryFailed
    implements
        UseCase<
          LaundryOrder,
          ({String orderId, TaskFailureReason reason, String? note})
        > {
  const ReportDeliveryFailed(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(
    ({String orderId, TaskFailureReason reason, String? note}) params,
  ) => _repo.reportDeliveryFailed(params.orderId, params.reason, params.note);
}
