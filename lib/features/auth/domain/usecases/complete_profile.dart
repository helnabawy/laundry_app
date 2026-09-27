import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/domain/repositories/address_repository.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class CompleteProfileParams extends Equatable {
  const CompleteProfileParams({required this.address, this.fullName});

  final NewAddress address;

  /// Only when the account still has no name — normally it was typed on the
  /// login screen and applied at verification.
  final String? fullName;

  @override
  List<Object?> get props => [fullName, address];
}

/// First-login onboarding (step 1.4): saves the customer's first pickup
/// address, and their name if login didn't already.
class CompleteProfile implements UseCase<AppUser, CompleteProfileParams> {
  const CompleteProfile(this._auth, this._addresses);

  final AuthRepository _auth;
  final AddressRepository _addresses;

  @override
  Future<Result<AppUser>> call(CompleteProfileParams params) async {
    final name = params.fullName?.trim();
    if ((name != null && name.isEmpty) || !params.address.isComplete) {
      return const Err(InputFailure(InputError.requiredField));
    }
    final added = await _addresses.addAddress(params.address);
    if (added case Err(:final failure)) return Err(failure);
    // Either call returns the user with `profileCompleted` now true.
    return name == null ? _auth.getMe() : _auth.updateProfile(fullName: name);
  }
}
