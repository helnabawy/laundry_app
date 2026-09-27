import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/digits.dart';
import '../entities/app_user.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams extends Equatable {
  const VerifyOtpParams({
    required this.phone,
    required this.code,
    this.fullName,
  });

  final PhoneNumber phone;
  final String code;

  /// Typed on the login screen for a number new to this device.
  final String? fullName;

  @override
  List<Object?> get props => [phone, code, fullName];
}

class VerifyOtp implements UseCase<AppUser, VerifyOtpParams> {
  const VerifyOtp(this._repository);

  final AuthRepository _repository;

  static final _codePattern = RegExp('^\\d{${AppConfig.otpLength}}\$');

  @override
  Future<Result<AppUser>> call(VerifyOtpParams params) async {
    final code = normalizeDigits(params.code.trim());
    if (!_codePattern.hasMatch(code)) {
      return const Err(InputFailure(InputError.invalidOtp));
    }
    final result = await _repository.verifyOtp(params.phone, code);
    // Operators/admins must use the web portal, not the mobile app.
    if (result case Ok(value: AppUser(role: UserRole.staff))) {
      await _repository.logout();
      return const Err(UnsupportedRoleFailure());
    }
    if (result case Ok(value: final user)) return _applyName(user, params);
    return result;
  }

  /// A new account takes the name typed at login. An existing one keeps the
  /// name it already has: the server's record wins over a retyped guess.
  Future<Result<AppUser>> _applyName(
    AppUser user,
    VerifyOtpParams params,
  ) async {
    final name = params.fullName?.trim() ?? '';
    if (name.isEmpty || (user.fullName?.trim().isNotEmpty ?? false)) {
      return Ok(user);
    }
    final named = await _repository.updateProfile(fullName: name);
    // Signed in either way; if the name didn't save, profile asks for it.
    return Ok(named.valueOrNull ?? user);
  }
}
