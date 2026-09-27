import '../../../../core/result/result.dart';
import '../entities/app_user.dart';
import '../entities/phone_number.dart';
import '../entities/saved_account.dart';

abstract interface class AuthRepository {
  /// Sends an SMS code (Unifonic / Message Central on the backend).
  Future<Result<void>> requestOtp(PhoneNumber phone);

  /// Verifies the code and persists the issued JWT.
  Future<Result<AppUser>> verifyOtp(PhoneNumber phone, String code);

  /// The signed-in user from a stored JWT, or null if there is none / it
  /// expired.
  Future<Result<AppUser?>> restoreSession();

  /// The signed-in user, fresh from the API.
  Future<Result<AppUser>> getMe();

  Future<Result<AppUser>> updateProfile({required String fullName});

  /// Signs out. The [savedAccount] stays, for signing back in.
  Future<Result<void>> logout();

  /// The last named customer or driver to sign in on this device.
  SavedAccount? savedAccount();
}
