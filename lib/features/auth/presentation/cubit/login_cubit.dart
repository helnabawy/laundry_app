import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/request_otp.dart';

class LoginState extends Equatable {
  const LoginState({this.submitting = false, this.failure, this.codeSentTo});

  final bool submitting;
  final Failure? failure;

  /// Set once the OTP was sent; the page navigates and then calls
  /// [LoginCubit.acknowledge].
  final PhoneNumber? codeSentTo;

  @override
  List<Object?> get props => [submitting, failure, codeSentTo];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._requestOtp) : super(const LoginState());

  final RequestOtp _requestOtp;

  Future<void> submit(String rawPhone) async {
    if (state.submitting) return;
    emit(const LoginState(submitting: true));
    final result = await _requestOtp(rawPhone);
    emit(
      result.fold(
        onErr: (failure) => LoginState(failure: failure),
        onOk: (phone) => LoginState(codeSentTo: phone),
      ),
    );
  }

  void acknowledge() => emit(const LoginState());

  void clearError() {
    if (state.failure != null) emit(const LoginState());
  }
}
