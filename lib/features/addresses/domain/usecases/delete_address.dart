import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/address_repository.dart';

/// Removes a saved address, refusing the last one: a customer always keeps
/// somewhere to be picked up from.
class DeleteAddress implements UseCase<void, String> {
  const DeleteAddress(this._repository);

  final AddressRepository _repository;

  @override
  Future<Result<void>> call(String id) async {
    final addresses = await _repository.getAddresses();
    switch (addresses) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value) when value.length <= 1:
        return const Err(LastAddressFailure());
      case Ok():
        return _repository.deleteAddress(id);
    }
  }
}
