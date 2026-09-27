import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/phone_number.dart';
import '../../domain/entities/saved_account.dart';

/// Keeps the last signed-in name + number in shared preferences. Neither is a
/// secret — the OTP still guards the account — so secure storage is reserved
/// for the JWT.
class SavedAccountLocalDataSource {
  const SavedAccountLocalDataSource(this._prefs);

  static const _key = 'saved_account';

  final SharedPreferences _prefs;

  SavedAccount? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final phone = PhoneNumber.tryParse(json['phone'] as String);
      final name = json['fullName'] as String;
      return phone == null ? null : SavedAccount(phone: phone, fullName: name);
    } on Object {
      // A shape from an older build: forget it rather than fail login.
      return null;
    }
  }

  Future<void> write(SavedAccount account) => _prefs.setString(
    _key,
    jsonEncode({'phone': account.phone.e164, 'fullName': account.fullName}),
  );
}
