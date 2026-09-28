import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App appearance. Follows the system until the user picks light or dark.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) =>
      ThemeMode.values.asNameMap()[prefs.getString(_key)] ?? ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_key, mode.name);
    emit(mode);
  }
}
