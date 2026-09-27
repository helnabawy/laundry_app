import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/entities/sign_in_request.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';

class OtpState extends Equatable {
  const OtpState({
    required this.secondsLeft,
    this.code = '',
    this.verifying = false,
    this.resending = false,
    this.resent = false,
    this.failure,
    this.user,
  });

  final String code;

  /// Countdown until "resend" is allowed (step 1.3).
  final int secondsLeft;
  final bool verifying;
  final bool resending;

  /// True right after a successful resend (for a one-off snackbar).
  final bool resent;
  final Failure? failure;

  /// Set when verification succeeded.
  final AppUser? user;

  bool get isComplete => code.length == AppConfig.otpLength;
  bool get canResend => secondsLeft == 0 && !resending;

  OtpState copyWith({
    String? code,
    int? secondsLeft,
    bool? verifying,
    bool? resending,
    bool? resent,
    ValueGetter<Failure?>? failure,
    AppUser? user,
  }) => OtpState(
    code: code ?? this.code,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    verifying: verifying ?? this.verifying,
    resending: resending ?? this.resending,
    resent: resent ?? false,
    failure: failure != null ? failure() : this.failure,
    user: user ?? this.user,
  );

  @override
  List<Object?> get props => [
    code,
    secondsLeft,
    verifying,
    resending,
    resent,
    failure,
    user,
  ];
}

class OtpCubit extends Cubit<OtpState> {
  OtpCubit({
    required this.request,
    required VerifyOtp verifyOtp,
    required RequestOtp requestOtp,
  }) : _verifyOtp = verifyOtp,
       _requestOtp = requestOtp,
       super(const OtpState(secondsLeft: AppConfig.otpResendSeconds)) {
    _startCountdown();
  }

  final SignInRequest request;
  final VerifyOtp _verifyOtp;
  final RequestOtp _requestOtp;
  Timer? _timer;

  PhoneNumber get phone => request.phone;

  void codeChanged(String code) {
    emit(state.copyWith(code: code, failure: () => null));
    if (state.isComplete) verify();
  }

  Future<void> verify() async {
    if (state.verifying || !state.isComplete) return;
    emit(state.copyWith(verifying: true, failure: () => null));
    final result = await _verifyOtp(
      VerifyOtpParams(
        phone: phone,
        code: state.code,
        fullName: request.fullName,
      ),
    );
    result.fold(
      onErr: (failure) =>
          emit(state.copyWith(verifying: false, failure: () => failure)),
      onOk: (user) => emit(state.copyWith(verifying: false, user: user)),
    );
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(resending: true, failure: () => null));
    final result = await _requestOtp(phone.e164);
    result.fold(
      onErr: (failure) =>
          emit(state.copyWith(resending: false, failure: () => failure)),
      onOk: (_) {
        emit(
          state.copyWith(
            resending: false,
            resent: true,
            code: '',
            secondsLeft: AppConfig.otpResendSeconds,
          ),
        );
        _startCountdown();
      },
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.secondsLeft - 1;
      emit(state.copyWith(secondsLeft: left < 0 ? 0 : left));
      if (left <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
