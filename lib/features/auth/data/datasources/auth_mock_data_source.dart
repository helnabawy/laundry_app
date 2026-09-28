import '../../../../core/error/exceptions.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../addresses/data/datasources/address_mock_data_source.dart';
import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';
import 'auth_remote_data_source.dart';

/// Accepts [MockDatabase.otpCode] for any number. Unknown numbers sign up as
/// new customers; see [MockDatabase] for the seeded customer and driver.
class AuthMockDataSource implements AuthRemoteDataSource {
  AuthMockDataSource(this._db, this._tokens) {
    AddressMockDataSource.seed(_db);
    _db.seedOnce(table, () {
      _db.table(table).addAll([
        {
          'id': MockDatabase.customerId,
          'phone': MockDatabase.customerPhone,
          'fullName': 'خالد المنصوري',
          'role': 'customer',
        },
        {
          'id': MockDatabase.driverId,
          'phone': MockDatabase.driverPhone,
          'fullName': 'أحمد علي',
          'role': 'driver',
        },
      ]);
    });
  }

  /// Shared with the orders mock, which resolves customer/driver names and
  /// phone numbers by id.
  static const table = 'users';
  static const _tokenPrefix = 'mock.';

  final MockDatabase _db;
  final TokenStorage _tokens;

  @override
  Future<void> requestOtp(String phone) => _db.delay();

  @override
  Future<bool> isRegistered(String phone) async {
    await _db.delay();
    final row = _db.table(table).where((u) => u['phone'] == phone).firstOrNull;
    if (row == null) return false;
    // A number that signed up but never gave a name still needs one.
    return row['role'] != 'customer' ||
        ((row['fullName'] as String?)?.trim().isNotEmpty ?? false);
  }

  @override
  Future<VerifyOtpResponse> verifyOtp(
    String phone,
    String code, {
    String? fullName,
  }) async {
    await _db.delay();
    if (code != MockDatabase.otpCode) _db.badRequest('Invalid code');
    final users = _db.table(table);
    final row = users.firstWhere(
      (u) => u['phone'] == phone,
      orElse: () {
        final created = {
          'id': 'usr-${_db.nextNumber()}',
          'phone': phone,
          'fullName': fullName?.trim().isNotEmpty ?? false
              ? fullName!.trim()
              : null,
          'role': 'customer',
        };
        users.add(created);
        return created;
      },
    );
    _db.currentUserId = row['id'] as String;
    return (token: '$_tokenPrefix${row['id']}', user: _toUser(row));
  }

  @override
  Future<AppUser> getMe() async {
    await _db.delay();
    final token = await _tokens.read();
    final row = token != null && token.startsWith(_tokenPrefix)
        ? _db.findById(table, token.substring(_tokenPrefix.length))
        : null;
    if (row == null) throw const UnauthorizedException();
    _db.currentUserId = row['id'] as String;
    return _toUser(row);
  }

  @override
  Future<AppUser> updateProfile(String fullName) async {
    await _db.delay();
    final row = _db.findById(table, _db.requireUserId())!;
    row['fullName'] = fullName;
    return _toUser(row);
  }

  AppUser _toUser(Map<String, dynamic> row) {
    final hasAddress = _db
        .table(AddressMockDataSource.table)
        .any((a) => a['userId'] == row['id']);
    final completed =
        row['role'] != 'customer' || (row['fullName'] != null && hasAddress);
    return AppUserModel.fromJson({...row, 'profileCompleted': completed});
  }
}
