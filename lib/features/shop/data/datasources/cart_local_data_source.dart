import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the cart's raw shape — product ids, quantities and the chosen
/// tier's id — in shared preferences. Nothing here knows about the live
/// catalog; re-resolving ids against it is the repository's job.
class CartLocalDataSource {
  const CartLocalDataSource(this._prefs);

  static const _key = 'cart_v1';

  final SharedPreferences _prefs;

  Map<String, dynamic>? readRaw() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on Object {
      // A shape from an older build: forget it rather than fail the load.
      return null;
    }
  }

  Future<void> writeRaw(Map<String, dynamic> json) =>
      _prefs.setString(_key, jsonEncode(json));

  Future<void> clear() => _prefs.remove(_key);
}
