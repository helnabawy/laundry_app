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
  const VerifyOtpParams({required this.phone, required this.code});

  final PhoneNumber phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
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
    return result;
  }
}
