import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/usecases/order_usecases.dart';

/// One order: used by both the tracking page and the invoice page, so
/// paying immediately reflects on the timeline behind it.
class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.order,
    this.loading = true,
    this.paying = false,
    this.failure,
  });

  final LaundryOrder? order;
  final bool loading;
  final bool paying;
  final Failure? failure;

  @override
  List<Object?> get props => [order, loading, paying, failure];
}

class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  OrderTrackingCubit(this._orderId, this._getOrder, this._choosePaymentMethod)
    : super(const OrderTrackingState()) {
    load();
  }

  final String _orderId;
  final GetOrder _getOrder;
  final ChoosePaymentMethod _choosePaymentMethod;

  Future<void> load() async {
    emit(OrderTrackingState(order: state.order, loading: true));
    final result = await _getOrder(_orderId);
    emit(
      result.fold(
        onErr: (f) => OrderTrackingState(order: state.order, loading: false, failure: f),
        onOk: (order) => OrderTrackingState(order: order, loading: false),
      ),
    );
  }

  Future<void> choosePaymentMethod(PaymentMethod method) async {
    emit(OrderTrackingState(order: state.order, loading: false, paying: true));
    final result = await _choosePaymentMethod((orderId: _orderId, method: method));
    emit(
      result.fold(
        onErr: (f) => OrderTrackingState(
          order: state.order,
          loading: false,
          failure: f,
        ),
        onOk: (order) => OrderTrackingState(order: order, loading: false),
      ),
    );
  }
}
