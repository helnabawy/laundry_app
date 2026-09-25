import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class UpdateAddressParams extends Equatable {
  const UpdateAddressParams({required this.id, required this.address});

  final String id;
  final NewAddress address;

  @override
  List<Object?> get props => [id, address];
}

class UpdateAddress implements UseCase<Address, UpdateAddressParams> {
  const UpdateAddress(this._repository);

  final AddressRepository _repository;

  @override
  Future<Result<Address>> call(UpdateAddressParams params) async {
    if (!params.address.isComplete) {
      return const Err(InputFailure(InputError.requiredField));
    }
    return _repository.updateAddress(params.id, params.address);
  }
}
