import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class GetAddresses implements UseCase<List<Address>, NoParams> {
  const GetAddresses(this._repository);

  final AddressRepository _repository;

  @override
  Future<Result<List<Address>>> call([NoParams params = const NoParams()]) =>
      _repository.getAddresses();
}
