import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/add_address.dart';
import '../../domain/usecases/delete_address.dart';
import '../../domain/usecases/update_address.dart';

/// How an address form finished.
sealed class AddressFormOutcome extends Equatable {
  const AddressFormOutcome();
}

final class AddressSaved extends AddressFormOutcome {
  const AddressSaved(this.address);

  final Address address;

  @override
  List<Object?> get props => [address];
}

final class AddressDeleted extends AddressFormOutcome {
  const AddressDeleted();

  @override
  List<Object?> get props => [];
}

class AddressFormState extends Equatable {
  const AddressFormState({this.busy = false, this.failure, this.outcome});

  final bool busy;
  final Failure? failure;
  final AddressFormOutcome? outcome;

  @override
  List<Object?> get props => [busy, failure, outcome];
}

/// Adds a new address, or edits / deletes an existing one when [editing] is
/// set.
class AddressFormCubit extends Cubit<AddressFormState> {
  AddressFormCubit(
    this._addAddress,
    this._updateAddress,
    this._deleteAddress, {
    this.editing,
  }) : super(const AddressFormState());

  final AddAddress _addAddress;
  final UpdateAddress _updateAddress;
  final DeleteAddress _deleteAddress;
  final Address? editing;

  Future<void> save(NewAddress address) async {
    emit(const AddressFormState(busy: true));
    final result = switch (editing) {
      final existing? => await _updateAddress(
        UpdateAddressParams(id: existing.id, address: address),
      ),
      null => await _addAddress(address),
    };
    emit(
      result.fold(
        onErr: (failure) => AddressFormState(failure: failure),
        onOk: (saved) => AddressFormState(outcome: AddressSaved(saved)),
      ),
    );
  }

  Future<void> delete() async {
    final existing = editing;
    if (existing == null) return;
    emit(const AddressFormState(busy: true));
    final result = await _deleteAddress(existing.id);
    emit(
      result.fold(
        onErr: (failure) => AddressFormState(failure: failure),
        onOk: (_) => const AddressFormState(outcome: AddressDeleted()),
      ),
    );
  }
}
