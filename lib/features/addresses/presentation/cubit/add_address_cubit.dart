import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/add_address.dart';

class AddAddressState extends Equatable {
  const AddAddressState({this.submitting = false, this.failure, this.created});

  final bool submitting;
  final Failure? failure;
  final Address? created;

  @override
  List<Object?> get props => [submitting, failure, created];
}

class AddAddressCubit extends Cubit<AddAddressState> {
  AddAddressCubit(this._addAddress) : super(const AddAddressState());

  final AddAddress _addAddress;

  Future<void> submit(NewAddress address) async {
    emit(const AddAddressState(submitting: true));
    final result = await _addAddress(address);
    emit(
      result.fold(
        onErr: (failure) => AddAddressState(failure: failure),
        onOk: (created) => AddAddressState(created: created),
      ),
    );
  }
}
