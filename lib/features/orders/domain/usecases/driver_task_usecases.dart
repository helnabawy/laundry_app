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
            bool hasPhoto,
          })
        > {
  const ReportPickupFailed(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(
    ({String orderId, TaskFailureReason reason, String? note, bool hasPhoto})
    params,
  ) => _repo.reportPickupFailed(
    params.orderId,
    params.reason,
    params.note,
    hasPhoto: params.hasPhoto,
  );
}

class ConfirmDelivery
    implements
        UseCase<
          LaundryOrder,
          ({String orderId, bool cashCollected, bool hasProofPhoto})
        > {
  const ConfirmDelivery(this._repo);
  final DriverTaskRepository _repo;

  @override
  Future<Result<LaundryOrder>> call(
    ({String orderId, bool cashCollected, bool hasProofPhoto}) params,
  ) => _repo.confirmDelivery(
    params.orderId,
    cashCollected: params.cashCollected,
    hasProofPhoto: params.hasProofPhoto,
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
