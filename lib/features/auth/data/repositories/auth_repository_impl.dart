import '../../../../core/error/failures.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokens);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<void>> requestOtp(PhoneNumber phone) =>
      guard(() => _remote.requestOtp(phone.e164));

  @override
  Future<Result<AppUser>> verifyOtp(PhoneNumber phone, String code) async {
    final result = await guard(() async {
      final response = await _remote.verifyOtp(phone.e164, code);
      await _tokens.write(response.token);
      return response.user;
    });
    // The API answers a wrong/expired code with 400.
    if (result case Err(failure: ServerFailure(statusCode: 400))) {
      return const Err(InputFailure(InputError.invalidOtp));
    }
    return result;
  }

  @override
  Future<Result<AppUser?>> restoreSession() async {
    if (await _tokens.read() == null) return const Ok(null);
    final result = await guard(_remote.getMe);
    if (result case Err(failure: UnauthorizedFailure())) {
      await _tokens.clear();
      return const Ok(null);
    }
    return result;
  }

  @override
  Future<Result<AppUser>> updateProfile({required String fullName}) =>
      guard(() => _remote.updateProfile(fullName));

  @override
  Future<Result<void>> logout() => guard(_tokens.clear);
}
