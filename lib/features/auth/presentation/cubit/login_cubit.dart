import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/entities/saved_account.dart';
import '../../domain/entities/sign_in_request.dart';
import '../../domain/usecases/check_phone.dart';
import '../../domain/usecases/get_saved_account.dart';
import '../../domain/usecases/start_sign_in.dart';

/// What the server knows about the number being typed.
enum PhoneStatus {
  /// Not a complete UAE number yet, or the check couldn't run.
  unknown,

  /// Asking the server whether the number is registered.
  checking,

  /// Has an account: log in with just the code.
  registered,

  /// New: give a full name, then verify the number with the code.
  unregistered,
}

class LoginState extends Equatable {
  const LoginState({
    this.savedAccount,
    this.usingSavedAccount = false,
    this.submitting = false,
    this.failure,
    this.codeSentTo,
    this.phoneStatus = PhoneStatus.unknown,
  });

  /// The account last signed in on this device, if any.
  final SavedAccount? savedAccount;

  /// Showing "welcome back" for [savedAccount] rather than the number form.
  final bool usingSavedAccount;
  final bool submitting;
  final Failure? failure;

  /// Set once the OTP was sent; the page navigates and then calls
  /// [LoginCubit.acknowledge].
  final SignInRequest? codeSentTo;

  /// Whether the typed number is known, which decides whether the name field
  /// shows and whether the button says "Log in" or "Verify".
  final PhoneStatus phoneStatus;

  /// The name field only shows for a number that isn't registered.
  bool get asksForName =>
      !usingSavedAccount && phoneStatus == PhoneStatus.unregistered;

  /// Logging in to an existing account (saved or typed).
  bool get isLogin =>
      usingSavedAccount || phoneStatus == PhoneStatus.registered;

  /// The name field is the one at fault; anything else shows under the
  /// number (or the saved account).
  bool get nameMissing =>
      failure == const InputFailure(InputError.requiredField);

  LoginState copyWith({
    bool? usingSavedAccount,
    bool? submitting,
    ValueGetter<Failure?>? failure,
    ValueGetter<SignInRequest?>? codeSentTo,
    PhoneStatus? phoneStatus,
  }) => LoginState(
    savedAccount: savedAccount,
    usingSavedAccount: usingSavedAccount ?? this.usingSavedAccount,
    submitting: submitting ?? this.submitting,
    failure: failure != null ? failure() : this.failure,
    codeSentTo: codeSentTo != null ? codeSentTo() : this.codeSentTo,
    phoneStatus: phoneStatus ?? this.phoneStatus,
  );

  @override
  List<Object?> get props => [
    savedAccount,
    usingSavedAccount,
    submitting,
    failure,
    codeSentTo,
    phoneStatus,
  ];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(
    this._startSignIn,
    GetSavedAccount getSavedAccount,
    this._checkPhone,
  ) : super(_initial(getSavedAccount()));

  final StartSignIn _startSignIn;
  final CheckPhone _checkPhone;

  /// The number [LoginState.phoneStatus] describes (E.164), or null.
  String? _statusFor;

  /// The number currently in the field, so a slow check for an older number
  /// never overwrites the answer for the current one.
  String? _typed;

  static LoginState _initial(SavedAccount? saved) =>
      LoginState(savedAccount: saved, usingSavedAccount: saved != null);

  /// One tap on the saved account: straight to the code, no typing.
  Future<void> continueWithSavedAccount() async {
    if (state.savedAccount case final saved?) {
      await _send(StartSignInParams(phone: saved.phone.e164));
    }
  }

  /// Checks a complete number as it is typed, so the form can switch to
  /// "Log in" or ask for a name before the button is pressed.
  Future<void> phoneChanged(String raw) async {
    clearError();
    final phone = PhoneNumber.tryParse(raw);
    _typed = phone?.e164;
    if (phone == null) {
      _statusFor = null;
      if (state.phoneStatus != PhoneStatus.unknown) {
        emit(state.copyWith(phoneStatus: PhoneStatus.unknown));
      }
      return;
    }
    if (_statusFor == phone.e164 && state.phoneStatus != PhoneStatus.unknown) {
      return;
    }
    await _check(phone.e164, raw);
  }

  /// "Log in" or "Verify". An unchecked number is checked first; a new one
  /// then shows the name field instead of sending a code without a name.
  Future<void> submit({required String phone, required String fullName}) async {
    final parsed = PhoneNumber.tryParse(phone);
    if (parsed == null) {
      emit(
        state.copyWith(
          failure: () => const InputFailure(InputError.invalidPhone),
        ),
      );
      return;
    }
    if (_statusFor != parsed.e164 ||
        state.phoneStatus == PhoneStatus.unknown ||
        state.phoneStatus == PhoneStatus.checking) {
      _typed = parsed.e164;
      await _check(parsed.e164, phone);
      if (state.phoneStatus == PhoneStatus.unregistered &&
          fullName.trim().isEmpty) {
        return; // The name field just appeared; let them fill it in.
      }
    }
    switch (state.phoneStatus) {
      case PhoneStatus.registered:
        // The account already has its name; nothing to type.
        await _send(StartSignInParams(phone: phone));
      case PhoneStatus.unregistered:
        await _send(StartSignInParams(phone: phone, fullName: fullName));
      case PhoneStatus.unknown || PhoneStatus.checking:
        // The check failed (offline?): send anyway, with any name typed.
        await _send(
          StartSignInParams(
            phone: phone,
            fullName: fullName.trim().isEmpty ? null : fullName,
          ),
        );
    }
  }

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

  Future<void> _check(String e164, String raw) async {
    emit(state.copyWith(phoneStatus: PhoneStatus.checking));
    final result = await _checkPhone(raw);
    if (isClosed || _typed != e164) return; // The number changed meanwhile.
    _statusFor = e164;
    emit(
      state.copyWith(
        phoneStatus: switch (result) {
          Ok(value: true) => PhoneStatus.registered,
          Ok(value: false) => PhoneStatus.unregistered,
          Err() => PhoneStatus.unknown,
        },
      ),
    );
  }

  Future<void> _send(StartSignInParams params) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, failure: () => null));
    final result = await _startSignIn(params);
    if (isClosed) return;
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
