import '../../../../core/error/failures.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/entities/saved_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/saved_account_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokens, this._savedAccount);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final SavedAccountLocalDataSource _savedAccount;

  @override
  Future<Result<void>> requestOtp(PhoneNumber phone) =>
      guard(() => _remote.requestOtp(phone.e164));

  @override
  Future<Result<AppUser>> verifyOtp(PhoneNumber phone, String code) async {
    final result = await guard(() async {
      final response = await _remote.verifyOtp(phone.e164, code);
      await _tokens.write(response.token);
      return _remember(response.user);
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
    final result = await getMe();
    if (result case Err(failure: UnauthorizedFailure())) {
      await _tokens.clear();
      return const Ok(null);
    }
    return result;
  }

  @override
  Future<Result<AppUser>> getMe() =>
      guard(() async => _remember(await _remote.getMe()));

  @override
  Future<Result<AppUser>> updateProfile({required String fullName}) =>
      guard(() async => _remember(await _remote.updateProfile(fullName)));

  @override
  Future<Result<void>> logout() => guard(_tokens.clear);

  @override
  SavedAccount? savedAccount() => _savedAccount.read();

  /// Every fresh [AppUser] refreshes the saved account, so a name changed on
  /// another device shows up here too. Staff never use this app, and an
  /// account with no name yet has nothing to greet.
  Future<AppUser> _remember(AppUser user) async {
    final name = user.fullName?.trim() ?? '';
    final phone = PhoneNumber.tryParse(user.phone);
    if (user.role != UserRole.staff && name.isNotEmpty && phone != null) {
      await _savedAccount.write(SavedAccount(phone: phone, fullName: name));
    }
    return user;
  }
}
