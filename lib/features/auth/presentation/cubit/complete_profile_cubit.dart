import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/complete_profile.dart';

class CompleteProfileState extends Equatable {
  const CompleteProfileState({
    this.submitting = false,
    this.failure,
    this.user,
  });

  final bool submitting;
  final Failure? failure;
  final AppUser? user;

  @override
  List<Object?> get props => [submitting, failure, user];
}

class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  CompleteProfileCubit(this._completeProfile)
    : super(const CompleteProfileState());

  final CompleteProfile _completeProfile;

  Future<void> submit({
    required String fullName,
    required NewAddress address,
  }) async {
    if (state.submitting) return;
    emit(const CompleteProfileState(submitting: true));
    final result = await _completeProfile(
      CompleteProfileParams(fullName: fullName, address: address),
    );
    emit(
      result.fold(
        onErr: (failure) => CompleteProfileState(failure: failure),
        onOk: (user) => CompleteProfileState(user: user),
      ),
    );
  }
}
