import '../../../../core/mock/mock_database.dart';
import '../../domain/entities/address.dart';
import '../models/address_model.dart';
import 'address_remote_data_source.dart';

class AddressMockDataSource implements AddressRemoteDataSource {
  AddressMockDataSource(this._db) {
    seed(_db);
  }

  static const table = 'addresses';

  final MockDatabase _db;

  static void seed(MockDatabase db) => db.seedOnce(table, () {
    db.table(table).addAll([
      {
        'id': 'adr-1',
        'userId': MockDatabase.customerId,
        'kind': 'home',
        'label': null,
        'city': 'أبوظبي',
        'area': 'الخالدية',
        'building': '12',
        'floor': '7',
        'apartment': '704',
        'alternatePhone': null,
        'latitude': 24.4672,
        'longitude': 54.3532,
      },
      {
        'id': 'adr-2',
        'userId': MockDatabase.customerId,
        'kind': 'work',
        'label': null,
        'city': 'أبوظبي',
        'area': 'الميناء',
        'building': '3',
        'floor': '2',
        'apartment': '210',
        'alternatePhone': null,
        'latitude': 24.5190,
        'longitude': 54.3790,
      },
    ]);
  });

  @override
  Future<List<Address>> getAddresses() async {
    await _db.delay();
    return _ownRows().map(AddressModel.fromJson).toList();
  }

  @override
  Future<Address> addAddress(NewAddress address) async {
    await _db.delay();
    final row = {
      'id': 'adr-${_db.nextNumber()}',
      'userId': _db.requireUserId(),
      ...AddressModel.toJson(address),
      'latitude': null,
      'longitude': null,
    };
    _db.table(table).add(row);
    return AddressModel.fromJson(row);
  }

  @override
  Future<Address> updateAddress(String id, NewAddress address) async {
    await _db.delay();
    final row = _ownRow(id)..addAll(AddressModel.toJson(address));
    return AddressModel.fromJson(row);
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _db.delay();
    final row = _ownRow(id);
    // Mirrors the API rule: a customer always keeps one pickup address.
    if (_ownRows().length <= 1) _db.badRequest('Cannot delete last address');
    _db.table(table).remove(row);
  }

  Iterable<Map<String, dynamic>> _ownRows() {
    final userId = _db.requireUserId();
    return _db.table(table).where((row) => row['userId'] == userId);
  }

  Map<String, dynamic> _ownRow(String id) => _ownRows().firstWhere(
    (row) => row['id'] == id,
    orElse: () => _db.notFound('Address not found'),
  );
}
