import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../entities/sign_in_request.dart';
import 'request_otp.dart';

class StartSignInParams extends Equatable {
  const StartSignInParams({required this.phone, this.fullName});

  final String phone;

  /// Required (non-blank) when given; null when signing in with the saved
  /// account, whose name is already known.
  final String? fullName;

  @override
  List<Object?> get props => [phone, fullName];
}

/// Login's "send code": validates the number, and the name for a number new
/// to this device, then requests the OTP (steps 1.2–1.3).
class StartSignIn implements UseCase<SignInRequest, StartSignInParams> {
  const StartSignIn(this._requestOtp);

  final RequestOtp _requestOtp;

  @override
  Future<Result<SignInRequest>> call(StartSignInParams params) async {
    // Checked in the order the fields sit on screen.
    if (PhoneNumber.tryParse(params.phone) == null) {
      return const Err(InputFailure(InputError.invalidPhone));
    }
    final name = params.fullName?.trim();
    if (name != null && name.isEmpty) {
      return const Err(InputFailure(InputError.requiredField));
    }
    final sent = await _requestOtp(params.phone);
    return sent.map((phone) => SignInRequest(phone: phone, fullName: name));
  }
}
