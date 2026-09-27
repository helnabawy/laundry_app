import 'package:equatable/equatable.dart';

import 'phone_number.dart';

/// The last account that signed in on this device, kept after logout so the
/// login screen can offer it back without retyping the number (step 1.2).
class SavedAccount extends Equatable {
  const SavedAccount({required this.phone, required this.fullName});

  final PhoneNumber phone;
  final String fullName;

  @override
  List<Object?> get props => [phone, fullName];
}
