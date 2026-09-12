import 'package:equatable/equatable.dart';

/// Role carried in the JWT. Customers and drivers share this app
/// (role-based UI); operators/admins use the web portal.
enum UserRole {
  customer,
  driver,
  staff;

  static UserRole fromJson(String value) => switch (value.toLowerCase()) {
    'customer' => customer,
    'driver' => driver,
    _ => staff,
  };
}

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.phone,
    required this.role,
    required this.profileCompleted,
    this.fullName,
  });

  final String id;

  /// E.164, e.g. `+971501234567`.
  final String phone;
  final String? fullName;
  final UserRole role;

  /// False on a customer's first login until name + address are saved
  /// (step 1.4).
  final bool profileCompleted;

  String get firstName => (fullName ?? '').trim().split(' ').first;

  @override
  List<Object?> get props => [id, phone, fullName, role, profileCompleted];
}
