import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/repositories/driver_task_repository.dart';
import '../../domain/usecases/driver_task_usecases.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../../../core/sync/refresh_bus.dart';

/// Backs both the pickup and delivery detail screens (plan §8.2): they
/// operate on the same [LaundryOrder], just at different statuses.
class TaskDetailState extends Equatable {
  const TaskDetailState({
    this.order,
    this.loading = true,
    this.submitting = false,
    this.done = false,
    this.failure,
  });

  final LaundryOrder? order;
  final bool loading;
  final bool submitting;

  /// The action (confirm/report-failed) succeeded — the page can pop.
  final bool done;
  final Failure? failure;

  @override
  List<Object?> get props => [order, loading, submitting, done, failure];
}

class TaskDetailCubit extends Cubit<TaskDetailState> with RefreshesOnSignal {
  TaskDetailCubit(
    this._orderId,
    this._getOrder,
    this._confirmPickup,
    this._reportPickupFailed,
    this._confirmDelivery,
    this._reportDeliveryFailed, {
    RefreshBus? refreshBus,
  }) : super(const TaskDetailState()) {
    load();
    refreshOn(
      refreshBus,
      (s) => (s is OrderChanged && s.orderId == _orderId) || s is AppResumed,
      _reloadUnlessBusy,
    );
  }

  /// A push mustn't clobber a confirm the driver is in the middle of.
  Future<void> _reloadUnlessBusy() async {
    if (!state.submitting) await load();
  }

  final String _orderId;
  final GetOrder _getOrder;
  final ConfirmPickup _confirmPickup;
  final ReportPickupFailed _reportPickupFailed;
  final ConfirmDelivery _confirmDelivery;
  final ReportDeliveryFailed _reportDeliveryFailed;

  Future<void> load() async {
    emit(TaskDetailState(order: state.order, loading: true));
    final result = await _getOrder(_orderId);
    emit(
      result.fold(
        onErr: (f) =>
            TaskDetailState(order: state.order, loading: false, failure: f),
        onOk: (order) => TaskDetailState(order: order, loading: false),
      ),
    );
  }

  Future<void> confirmPickup() => _run(() => _confirmPickup(_orderId));

  Future<void> reportPickupFailed(
    TaskFailureReason reason,
    String? note, {
    required String photoPath,
  }) => _run(
    () => _reportPickupFailed((
      orderId: _orderId,
      reason: reason,
      note: note,
      photoPath: photoPath,
    )),
  );

  Future<void> confirmDelivery({
    required bool cashCollected,
    String? proofPhotoPath,
  }) => _run(
    () => _confirmDelivery((
      orderId: _orderId,
      cashCollected: cashCollected,
      proofPhotoPath: proofPhotoPath,
    )),
  );

  Future<void> reportDeliveryFailed(TaskFailureReason reason, String? note) =>
      _run(
        () => _reportDeliveryFailed((
          orderId: _orderId,
          reason: reason,
          note: note,
        )),
      );

  Future<void> _run(Future<Result<LaundryOrder>> Function() action) async {
    emit(TaskDetailState(order: state.order, loading: false, submitting: true));
    final result = await action();
    emit(
      result.fold(
        onErr: (f) =>
            TaskDetailState(order: state.order, loading: false, failure: f),
        onOk: (order) =>
            TaskDetailState(order: order, loading: false, done: true),
      ),
    );
  }
}
