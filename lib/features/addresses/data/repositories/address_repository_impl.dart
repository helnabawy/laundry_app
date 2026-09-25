import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_data_source.dart';

class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl(this._remote);

  final AddressRemoteDataSource _remote;

  @override
  Future<Result<List<Address>>> getAddresses() => guard(_remote.getAddresses);

  @override
  Future<Result<Address>> addAddress(NewAddress address) =>
      guard(() => _remote.addAddress(address));

  @override
  Future<Result<Address>> updateAddress(String id, NewAddress address) =>
      guard(() => _remote.updateAddress(id, address));

  @override
  Future<Result<void>> deleteAddress(String id) =>
      guard(() => _remote.deleteAddress(id));
}
