import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

/// Is this number already registered? Drives the login screen: a known
/// number logs in with just the code; a new one also gives a full name.
class CheckPhone implements UseCase<bool, String> {
  const CheckPhone(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<bool>> call(String rawPhone) async {
    final phone = PhoneNumber.tryParse(rawPhone);
    if (phone == null) return const Err(InputFailure(InputError.invalidPhone));
    return _repository.isRegistered(phone);
  }
}
