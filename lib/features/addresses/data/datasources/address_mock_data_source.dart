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
    db.table(table).add({
      'id': 'adr-1',
      'userId': MockDatabase.customerId,
      'label': 'Home',
      'city': 'أبوظبي',
      'area': 'الخالدية',
      'building': '12',
      'floor': '7',
      'apartment': '704',
      'alternatePhone': null,
      'latitude': 24.4672,
      'longitude': 54.3532,
    });
  });

  @override
  Future<List<Address>> getAddresses() async {
    await _db.delay();
    final userId = _db.requireUserId();
    return _db
        .table(table)
        .where((row) => row['userId'] == userId)
        .map(AddressModel.fromJson)
        .toList();
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
}
