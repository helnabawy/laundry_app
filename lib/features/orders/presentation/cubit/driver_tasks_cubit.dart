import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/driver_task.dart';
import '../../domain/usecases/driver_task_usecases.dart';
import '../../../../core/sync/refresh_bus.dart';

/// Plan §8.2 "مهام اليوم" + §8.3-adjacent "السجل" (history) tab.
class DriverTasksState extends Equatable {
  const DriverTasksState({
    this.tasks = const [],
    this.completed = const [],
    this.available = true,
    this.loading = true,
    this.togglingAvailability = false,
    this.failure,
  });

  final List<DriverTask> tasks;
  final List<DriverTask> completed;
  final bool available;
  final bool loading;
  final bool togglingAvailability;
  final Failure? failure;

  List<DriverTask> get pickups =>
      tasks.where((t) => t.type == TaskType.pickup).toList();
  List<DriverTask> get deliveries =>
      tasks.where((t) => t.type == TaskType.delivery).toList();

  DriverTasksState copyWith({
    List<DriverTask>? tasks,
    List<DriverTask>? completed,
    bool? available,
    bool? loading,
    bool? togglingAvailability,
    Failure? failure,
  }) => DriverTasksState(
    tasks: tasks ?? this.tasks,
    completed: completed ?? this.completed,
    available: available ?? this.available,
    loading: loading ?? this.loading,
    togglingAvailability: togglingAvailability ?? this.togglingAvailability,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    tasks,
    completed,
    available,
    loading,
    togglingAvailability,
    failure,
  ];
}

class DriverTasksCubit extends Cubit<DriverTasksState> with RefreshesOnSignal {
  DriverTasksCubit(
    this._getTodayTasks,
    this._getCompletedTasks,
    this._setAvailability, {
    RefreshBus? refreshBus,
  }) : super(const DriverTasksState()) {
    refreshOn(refreshBus, (s) => s is OrderChanged || s is AppResumed, load);
  }

  final GetTodayTasks _getTodayTasks;
  final GetCompletedTasks _getCompletedTasks;
  final SetAvailability _setAvailability;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final results = await (_getTodayTasks(), _getCompletedTasks()).wait;
    final failure = results.$1.failureOrNull ?? results.$2.failureOrNull;
    emit(
      state.copyWith(
        tasks: results.$1.valueOrNull ?? state.tasks,
        completed: results.$2.valueOrNull ?? state.completed,
        loading: false,
        failure: failure,
      ),
    );
  }

  Future<void> setAvailability(bool available) async {
    emit(state.copyWith(togglingAvailability: true));
    final result = await _setAvailability(available);
    emit(
      result.fold(
        onErr: (f) => state.copyWith(togglingAvailability: false, failure: f),
        onOk: (value) =>
            state.copyWith(available: value, togglingAvailability: false),
      ),
    );
  }
}
