import '../../domain/entities/app_user.dart';

abstract final class AppUserModel {
  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    fullName: json['fullName'] as String?,
    role: UserRole.fromJson(json['role'] as String),
    profileCompleted: json['profileCompleted'] as bool? ?? false,
  );
}
