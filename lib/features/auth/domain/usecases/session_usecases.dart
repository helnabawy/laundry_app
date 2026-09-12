import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RestoreSession implements UseCase<AppUser?, NoParams> {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AppUser?>> call([NoParams params = const NoParams()]) =>
      _repository.restoreSession();
}

class Logout implements UseCase<void, NoParams> {
  const Logout(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.logout();
}
