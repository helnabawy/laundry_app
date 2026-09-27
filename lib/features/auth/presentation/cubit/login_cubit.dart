import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/saved_account.dart';
import '../../domain/entities/sign_in_request.dart';
import '../../domain/usecases/get_saved_account.dart';
import '../../domain/usecases/start_sign_in.dart';

class LoginState extends Equatable {
  const LoginState({
    this.savedAccount,
    this.usingSavedAccount = false,
    this.submitting = false,
    this.failure,
    this.codeSentTo,
  });

  /// The account last signed in on this device, if any.
  final SavedAccount? savedAccount;

  /// Showing "welcome back" for [savedAccount] rather than the number + name
  /// form.
  final bool usingSavedAccount;
  final bool submitting;
  final Failure? failure;

  /// Set once the OTP was sent; the page navigates and then calls
  /// [LoginCubit.acknowledge].
  final SignInRequest? codeSentTo;

  /// The name field is the one at fault; anything else shows under the
  /// number (or the saved account).
  bool get nameMissing =>
      failure == const InputFailure(InputError.requiredField);

  LoginState copyWith({
    bool? usingSavedAccount,
    bool? submitting,
    ValueGetter<Failure?>? failure,
    ValueGetter<SignInRequest?>? codeSentTo,
  }) => LoginState(
    savedAccount: savedAccount,
    usingSavedAccount: usingSavedAccount ?? this.usingSavedAccount,
    submitting: submitting ?? this.submitting,
    failure: failure != null ? failure() : this.failure,
    codeSentTo: codeSentTo != null ? codeSentTo() : this.codeSentTo,
  );

  @override
  List<Object?> get props => [
    savedAccount,
    usingSavedAccount,
    submitting,
    failure,
    codeSentTo,
  ];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._startSignIn, GetSavedAccount getSavedAccount)
    : super(_initial(getSavedAccount()));

  final StartSignIn _startSignIn;

  static LoginState _initial(SavedAccount? saved) =>
      LoginState(savedAccount: saved, usingSavedAccount: saved != null);

  /// One tap on the saved account: straight to the code, no typing.
  Future<void> continueWithSavedAccount() async {
    if (state.savedAccount case final saved?) {
      await _send(StartSignInParams(phone: saved.phone.e164));
    }
  }

  /// A number typed by hand always comes with a name (step 1.4).
  Future<void> submit({required String phone, required String fullName}) =>
      _send(StartSignInParams(phone: phone, fullName: fullName));

  void useAnotherNumber() =>
      emit(state.copyWith(usingSavedAccount: false, failure: () => null));

  void useSavedAccount() {
    if (state.savedAccount == null) return;
    emit(state.copyWith(usingSavedAccount: true, failure: () => null));
  }

  void acknowledge() => emit(state.copyWith(codeSentTo: () => null));

  void clearError() {
    if (state.failure != null) emit(state.copyWith(failure: () => null));
  }

  Future<void> _send(StartSignInParams params) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, failure: () => null));
    final result = await _startSignIn(params);
    emit(
      result.fold(
        onErr: (failure) =>
            state.copyWith(submitting: false, failure: () => failure),
        onOk: (request) =>
            state.copyWith(submitting: false, codeSentTo: () => request),
      ),
    );
  }
}
