import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/monitoring/app_reporter.dart';
import '../../domain/entities/payment_info.dart';
import '../../domain/usecases/payment_usecases.dart';

class PaymentStatusState extends Equatable {
  const PaymentStatusState({this.payment, this.checking = false, this.failure});

  final PaymentInfo? payment;

  /// Asking the server whether the checkout went through.
  final bool checking;
  final Failure? failure;

  @override
  List<Object?> get props => [payment, checking, failure];
}

/// Follows one payment after the customer is sent to its checkout. The
/// provider tells the server, not the app, so this asks the server — a few
/// times with growing gaps, since a webhook can land a moment after the
/// customer is back.
class PaymentStatusCubit extends Cubit<PaymentStatusState> {
  PaymentStatusCubit(
    this._getStatus, {
    this.backoff = const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
    AppReporter reporter = const NoopReporter(),
  }) : _reporter = reporter,
       super(const PaymentStatusState());

  final GetPaymentStatus _getStatus;
  final AppReporter _reporter;
  final List<Duration> backoff;

  void track(PaymentInfo? payment) =>
      emit(PaymentStatusState(payment: payment));

  Future<void> check() async {
    final payment = state.payment;
    if (payment == null || state.checking || !payment.isPending) return;
    emit(PaymentStatusState(payment: payment, checking: true));
    for (final wait in backoff) {
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (isClosed) return;
      final result = await _getStatus(payment.id);
      if (isClosed) return;
      if (result.failureOrNull case final failure?) {
        emit(PaymentStatusState(payment: state.payment, failure: failure));
        return;
      }
      final latest = result.valueOrNull!;
      if (!latest.isPending) {
        _reporter.track(
          AnalyticsEvent.paymentStatus(
            status: latest.status.name,
            provider: latest.provider.name,
          ),
        );
        emit(PaymentStatusState(payment: latest));
        return;
      }
      emit(PaymentStatusState(payment: latest, checking: true));
    }
    emit(PaymentStatusState(payment: state.payment));
  }
}
