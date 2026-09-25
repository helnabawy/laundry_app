import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/get_addresses.dart';

/// The customer's saved addresses, for "My addresses" in the account tab.
class AddressesState extends Equatable {
  const AddressesState({
    this.addresses = const [],
    this.loading = true,
    this.failure,
  });

  final List<Address> addresses;
  final bool loading;
  final Failure? failure;

  @override
  List<Object?> get props => [addresses, loading, failure];
}

class AddressesCubit extends Cubit<AddressesState> {
  AddressesCubit(this._getAddresses) : super(const AddressesState());

  final GetAddresses _getAddresses;

  Future<void> load() async {
    emit(AddressesState(addresses: state.addresses));
    final result = await _getAddresses();
    emit(
      result.fold(
        onErr: (failure) => AddressesState(
          addresses: state.addresses,
          loading: false,
          failure: failure,
        ),
        onOk: (addresses) =>
            AddressesState(addresses: addresses, loading: false),
      ),
    );
  }
}
