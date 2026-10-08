import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/laundry.dart';
import '../../domain/repositories/laundry_repository.dart';

const _unset = Object();

class LaundryState extends Equatable {
  const LaundryState({
    this.selected,
    this.laundries = const [],
    this.loading = false,
    this.failure,
  });

  /// The laundry this device orders from; null until the customer picks one.
  final Laundry? selected;

  /// Every active laundry, once [LaundryCubit.load] has succeeded.
  final List<Laundry> laundries;
  final bool loading;
  final Failure? failure;

  /// There is more than one laundry to choose between.
  bool get hasChoice => laundries.length > 1;

  LaundryState copyWith({
    Object? selected = _unset,
    List<Laundry>? laundries,
    bool? loading,
    Object? failure = _unset,
  }) => LaundryState(
    selected: identical(selected, _unset)
        ? this.selected
        : selected as Laundry?,
    laundries: laundries ?? this.laundries,
    loading: loading ?? this.loading,
    failure: identical(failure, _unset) ? this.failure : failure as Failure?,
  );

  @override
  List<Object?> get props => [selected, laundries, loading, failure];
}

/// App-wide: which laundry the customer orders from. The choice survives
/// restarts (and works offline); every catalogue, slot and order request is
/// sent for it (see `dio_factory.dart`).
class LaundryCubit extends Cubit<LaundryState> {
  LaundryCubit(this._repository)
    : super(LaundryState(selected: _repository.savedLaundry()));

  final LaundryRepository _repository;

  /// Fetches the active laundries and reconciles the saved choice with them:
  /// a laundry that stopped accepting orders is dropped; the only laundry is
  /// picked automatically.
  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: null));
    final result = await _repository.getLaundries();
    final laundries = result.valueOrNull;
    if (laundries == null) {
      emit(state.copyWith(loading: false, failure: result.failureOrNull));
      return;
    }
    final current = state.selected;
    final fresh = current == null
        ? null
        : laundries.where((l) => l.id == current.id).firstOrNull;
    final selected = fresh ?? (laundries.length == 1 ? laundries.single : null);
    if (selected != current) await _repository.saveLaundry(selected);
    emit(
      LaundryState(selected: selected, laundries: laundries, loading: false),
    );
  }

  Future<void> choose(Laundry laundry) async {
    if (laundry == state.selected) return;
    await _repository.saveLaundry(laundry);
    emit(state.copyWith(selected: laundry));
  }

  /// Reordering repeats an order at the laundry that handled it, so the
  /// products, tiers and slots it refers to exist. No-op when that laundry is
  /// already chosen, unknown, or no longer taking orders.
  Future<void> switchTo(String? laundryId) async {
    if (laundryId == null || laundryId == state.selected?.id) return;
    if (state.laundries.isEmpty) await load();
    final match = state.laundries.where((l) => l.id == laundryId).firstOrNull;
    if (match != null) await choose(match);
  }

  /// On sign-out: the next account on this phone picks its own laundry.
  Future<void> forget() async {
    await _repository.saveLaundry(null);
    emit(state.copyWith(selected: null));
  }
}
