import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../../../core/sync/refresh_bus.dart';

/// The customer's order list, shared by the home screen and "My orders"
/// (plan §8.1 "الطلب الحالي" / "طلباتك السابقة" / "طلباتي").
class OrdersState extends Equatable {
  const OrdersState({
    this.orders = const [],
    this.loading = true,
    this.failure,
  });

  final List<LaundryOrder> orders;
  final bool loading;
  final Failure? failure;

  List<LaundryOrder> get active =>
      orders.where((o) => o.status.isActive).toList();
  List<LaundryOrder> get past => orders.where((o) => o.status.isPast).toList();
  LaundryOrder? get current => active.isEmpty ? null : active.first;

  /// The customer's latest order was cancelled because the driver couldn't
  /// collect it, and nothing has been booked since — so home asks them to
  /// pick a new time. Orders arrive newest first.
  LaundryOrder? get failedPickupToReschedule => switch (orders) {
    [final latest, ...] when latest.pickupFailedAndCancelled => latest,
    _ => null,
  };

  @override
  List<Object?> get props => [orders, loading, failure];
}

class OrdersCubit extends Cubit<OrdersState> with RefreshesOnSignal {
  OrdersCubit(this._getOrders, {RefreshBus? refreshBus})
    : super(const OrdersState()) {
    refreshOn(refreshBus, (s) => s is OrderChanged || s is AppResumed, load);
  }

  final GetOrders _getOrders;

  Future<void> load() async {
    emit(OrdersState(orders: state.orders, loading: true));
    final result = await _getOrders();
    emit(
      result.fold(
        onErr: (f) =>
            OrdersState(orders: state.orders, loading: false, failure: f),
        onOk: (orders) => OrdersState(orders: orders, loading: false),
      ),
    );
  }
}
