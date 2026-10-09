import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/monitoring/app_reporter.dart';
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
    AppReporter reporter = const NoopReporter(),
  }) : _reporter = reporter,
       super(const TaskDetailState()) {
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
  final AppReporter _reporter;
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

  Future<void> confirmPickup() =>
      _run('confirm_pickup', () => _confirmPickup(_orderId));

  Future<void> reportPickupFailed(
    TaskFailureReason reason,
    String? note, {
    required String photoPath,
  }) => _run(
    'pickup_failed',
    reason: reason.name,
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
    'confirm_delivery',
    () => _confirmDelivery((
      orderId: _orderId,
      cashCollected: cashCollected,
      proofPhotoPath: proofPhotoPath,
    )),
  );

  Future<void> reportDeliveryFailed(TaskFailureReason reason, String? note) =>
      _run(
        'delivery_failed',
        reason: reason.name,
        () => _reportDeliveryFailed((
          orderId: _orderId,
          reason: reason,
          note: note,
        )),
      );

  Future<void> _run(
    String name,
    Future<Result<LaundryOrder>> Function() action, {
    String? reason,
  }) async {
    emit(TaskDetailState(order: state.order, loading: false, submitting: true));
    final result = await action();
    _reporter.track(
      AnalyticsEvent.driverTask(
        action: name,
        success: result is Ok,
        reason: reason,
      ),
    );
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
