import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/laundry.dart';
import '../../domain/repositories/laundry_repository.dart';
import '../datasources/laundry_remote_data_source.dart';
import '../models/laundry_model.dart';

class LaundryRepositoryImpl implements LaundryRepository {
  const LaundryRepositoryImpl(this._remote, this._prefs);

  static const _key = 'selected_laundry';

  final LaundryRemoteDataSource _remote;
  final SharedPreferences _prefs;

  @override
  Future<Result<List<Laundry>>> getLaundries() => guard(_remote.getLaundries);

  @override
  Laundry? savedLaundry() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return LaundryModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveLaundry(Laundry? laundry) async {
    if (laundry == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, jsonEncode(LaundryModel.toJson(laundry)));
    }
  }
}
