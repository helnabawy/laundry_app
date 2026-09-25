import '../../../../core/result/result.dart';
import '../entities/address.dart';

abstract interface class AddressRepository {
  Future<Result<List<Address>>> getAddresses();
  Future<Result<Address>> addAddress(NewAddress address);
  Future<Result<Address>> updateAddress(String id, NewAddress address);
  Future<Result<void>> deleteAddress(String id);
}
