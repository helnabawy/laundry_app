import '../entities/saved_account.dart';
import '../repositories/auth_repository.dart';

/// Read synchronously so the login screen opens on the right view with no
/// flash of the empty form.
class GetSavedAccount {
  const GetSavedAccount(this._repository);

  final AuthRepository _repository;

  SavedAccount? call() => _repository.savedAccount();
}
