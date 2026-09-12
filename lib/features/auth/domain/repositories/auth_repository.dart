import '../../../../core/result/result.dart';
import '../entities/app_user.dart';
import '../entities/phone_number.dart';

abstract interface class AuthRepository {
  /// Sends an SMS code (Unifonic / Message Central on the backend).
  Future<Result<void>> requestOtp(PhoneNumber phone);

  /// Verifies the code and persists the issued JWT.
  Future<Result<AppUser>> verifyOtp(PhoneNumber phone, String code);

  /// The signed-in user from a stored JWT, or null if there is none / it
  /// expired.
  Future<Result<AppUser?>> restoreSession();

  Future<Result<AppUser>> updateProfile({required String fullName});

  Future<Result<void>> logout();
}
