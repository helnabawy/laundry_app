import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

/// Validates the typed number and requests an OTP for it.
class RequestOtp implements UseCase<PhoneNumber, String> {
  const RequestOtp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<PhoneNumber>> call(String rawPhone) async {
    final phone = PhoneNumber.tryParse(rawPhone);
    if (phone == null) return const Err(InputFailure(InputError.invalidPhone));
    final result = await _repository.requestOtp(phone);
    return result.map((_) => phone);
  }
}
