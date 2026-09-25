import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/address.dart';
import '../models/address_model.dart';

abstract interface class AddressRemoteDataSource {
  Future<List<Address>> getAddresses();
  Future<Address> addAddress(NewAddress address);
  Future<Address> updateAddress(String id, NewAddress address);
  Future<void> deleteAddress(String id);
}

class AddressApiDataSource implements AddressRemoteDataSource {
  const AddressApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<Address>> getAddresses() async {
    final json = await _api.get(ApiEndpoints.addresses) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(AddressModel.fromJson)
        .toList();
  }

  @override
  Future<Address> addAddress(NewAddress address) async {
    final json = await _api.post(
      ApiEndpoints.addresses,
      data: AddressModel.toJson(address),
    );
    return AddressModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Address> updateAddress(String id, NewAddress address) async {
    final json = await _api.put(
      ApiEndpoints.address(id),
      data: AddressModel.toJson(address),
    );
    return AddressModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAddress(String id) =>
      _api.delete(ApiEndpoints.address(id));
}
