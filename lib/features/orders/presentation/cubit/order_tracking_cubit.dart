import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/payment_info.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../../../../core/sync/refresh_bus.dart';

/// One order: used by both the tracking page and the invoice page, so
/// paying immediately reflects on the timeline behind it.
class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.order,
    this.loading = true,
    this.paying = false,
    this.rating = false,
    this.failure,
  });

  final LaundryOrder? order;
  final bool loading;
  final bool paying;

  /// The customer's stars are being sent.
  final bool rating;
  final Failure? failure;

  @override
  List<Object?> get props => [order, loading, paying, rating, failure];
}

class OrderTrackingCubit extends Cubit<OrderTrackingState>
    with RefreshesOnSignal {
  OrderTrackingCubit(
    this._orderId,
    this._getOrder,
    this._choosePaymentMethod,
    this._rateOrder, {
    RetryPayment? retryPayment,
    RefreshBus? refreshBus,
  }) : _retryPayment = retryPayment,
       super(const OrderTrackingState()) {
    load();
    refreshOn(
      refreshBus,
      (s) => (s is OrderChanged && s.orderId == _orderId) || s is AppResumed,
      _reloadUnlessBusy,
    );
  }

  /// A push mustn't clobber a payment or rating in flight.
  Future<void> _reloadUnlessBusy() async {
    if (!state.paying && !state.rating) await load();
  }

  final String _orderId;
  final GetOrder _getOrder;
  final ChoosePaymentMethod _choosePaymentMethod;
  final RateOrder _rateOrder;
  final RetryPayment? _retryPayment;

  Future<void> load() async {
    emit(OrderTrackingState(order: state.order, loading: true));
    final result = await _getOrder(_orderId);
    emit(
      result.fold(
        onErr: (f) =>
            OrderTrackingState(order: state.order, loading: false, failure: f),
        onOk: (order) => OrderTrackingState(order: order, loading: false),
      ),
    );
  }

  Future<void> choosePaymentMethod(
    PaymentMethod method, {
    required bool conditionsAcknowledged,
  }) async {
    emit(OrderTrackingState(order: state.order, loading: false, paying: true));
    final result = await _choosePaymentMethod((
      orderId: _orderId,
      method: method,
      conditionsAcknowledged: conditionsAcknowledged,
    ));
    emit(
      result.fold(
        onErr: (f) =>
            OrderTrackingState(order: state.order, loading: false, failure: f),
        onOk: (order) => OrderTrackingState(order: order, loading: false),
      ),
    );
  }

  /// Opens a fresh checkout after a declined, cancelled or expired one.
  /// Returns the new pending payment, or null when it couldn't be opened.
  Future<PaymentInfo?> retryPayment({PaymentMethod? method}) async {
    final retry = _retryPayment;
    if (retry == null || state.paying) return null;
    emit(OrderTrackingState(order: state.order, loading: false, paying: true));
    final result = await retry((orderId: _orderId, method: method));
    if (isClosed) return null;
    emit(
      result.fold(
        onErr: (f) =>
            OrderTrackingState(order: state.order, loading: false, failure: f),
        onOk: (order) => OrderTrackingState(order: order, loading: false),
      ),
    );
    return result.valueOrNull?.invoice?.payment;
  }

  Future<void> rate(int stars, {String? comment}) async {
    if (state.rating) return;
    emit(OrderTrackingState(order: state.order, loading: false, rating: true));
    final result = await _rateOrder((
      orderId: _orderId,
      stars: stars,
      comment: comment,
    ));
    emit(
      result.fold(
        onErr: (f) =>
            OrderTrackingState(order: state.order, loading: false, failure: f),
        onOk: (order) => OrderTrackingState(order: order, loading: false),
      ),
    );
  }
}
