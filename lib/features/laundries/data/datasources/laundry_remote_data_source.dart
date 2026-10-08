import '../../../../core/mock/mock_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/laundry.dart';
import '../models/laundry_model.dart';

abstract interface class LaundryRemoteDataSource {
  Future<List<Laundry>> getLaundries();
}

class LaundryApiDataSource implements LaundryRemoteDataSource {
  const LaundryApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<Laundry>> getLaundries() async {
    final json = await _api.get(ApiEndpoints.laundries) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(LaundryModel.fromJson)
        .toList();
  }
}

/// Two laundries, so the picker and the "change laundry" flow can be demoed
/// without a backend. Both serve the mock's single catalogue.
class LaundryMockDataSource implements LaundryRemoteDataSource {
  const LaundryMockDataSource(this._db);

  final MockDatabase _db;

  static final _rows = [
    {
      'id': MockDatabase.facilityId,
      'slug': 'main',
      'name': {'en': 'Main Laundry', 'ar': 'المغسلة الرئيسية'},
      'phone': '+97125550100',
      'address': {'en': 'Al Khalidiya, Street 12', 'ar': 'الخالدية، شارع 12'},
      'city': 'Abu Dhabi',
      'area': 'Al Khalidiya',
      'codFee': 5,
    },
    {
      'id': 'fac-2',
      'slug': 'marina',
      'name': {'en': 'Marina Laundry', 'ar': 'مغسلة المارينا'},
      'phone': '+97125550200',
      'address': {'en': 'Al Mina, Port Road', 'ar': 'الميناء، طريق الميناء'},
      'city': 'Abu Dhabi',
      'area': 'Al Mina',
      'codFee': 5,
    },
  ];

  @override
  Future<List<Laundry>> getLaundries() async {
    await _db.delay();
    return [
      for (final row in _rows)
        LaundryModel.fromJson({
          ...row,
          'name': _db.tr(row['name']),
          'address': _db.tr(row['address']),
        }),
    ];
  }
}
