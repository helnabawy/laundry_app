import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class AddAddress implements UseCase<Address, NewAddress> {
  const AddAddress(this._repository);

  final AddressRepository _repository;

  @override
  Future<Result<Address>> call(NewAddress params) async {
    if (!params.isComplete) {
      return const Err(InputFailure(InputError.requiredField));
    }
    return _repository.addAddress(params);
  }
}
