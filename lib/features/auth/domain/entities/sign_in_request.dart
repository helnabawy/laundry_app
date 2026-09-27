import 'package:equatable/equatable.dart';

import 'phone_number.dart';

/// A number an OTP was sent to, plus the name typed alongside it when the
/// number is new to this device. Carried from login to the OTP screen.
class SignInRequest extends Equatable {
  const SignInRequest({required this.phone, this.fullName});

  final PhoneNumber phone;

  /// Applied to the account after verification if it has no name yet.
  final String? fullName;

  @override
  List<Object?> get props => [phone, fullName];
}
