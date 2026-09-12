import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language. `null` until the user picks one on first launch (step 1.1).
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._prefs) : super(_read(_prefs));

  static const _key = 'language_code';
  static const fallbackLanguageCode = 'ar';

  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    return code == null ? null : Locale(code);
  }

  bool get hasChosenLanguage => state != null;

  String get languageCode => state?.languageCode ?? fallbackLanguageCode;

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_key, code);
    emit(Locale(code));
  }
}
