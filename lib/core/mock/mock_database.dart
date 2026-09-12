import '../error/exceptions.dart';

/// In-memory stand-in for the ASP.NET Core API, used when
/// `USE_MOCK_API=true` (the default until the backend is deployed).
///
/// Mock data sources read and write JSON rows here in the same shapes the
/// real API returns, so the same models parse both. Data lives for the app
/// session only.
class MockDatabase {
  MockDatabase({
    required this.languageCode,
    this.latency = const Duration(milliseconds: 400),
  });

  static const otpCode = '1234';
  static const facilityId = 'fac-1';
  static const customerId = 'usr-customer-1';
  static const driverId = 'usr-driver-1';
  static const customerPhone = '+971501234567';
  static const driverPhone = '+971500000001';

  final String Function() languageCode;
  final Duration latency;

  final _tables = <String, List<Map<String, dynamic>>>{};
  final _seeded = <String>{};
  var _sequence = 1100;

  /// The signed-in user (the "JWT subject").
  String? currentUserId;

  List<Map<String, dynamic>> table(String name) =>
      _tables.putIfAbsent(name, () => []);

  Map<String, dynamic>? findById(String tableName, String id) {
    for (final row in table(tableName)) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  /// Runs [seed] the first time [key] is requested.
  void seedOnce(String key, void Function() seed) {
    if (_seeded.add(key)) seed();
  }

  int nextNumber() => ++_sequence;

  Future<void> delay() => Future<void>.delayed(latency);

  String requireUserId() {
    final id = currentUserId;
    if (id == null) throw const UnauthorizedException();
    return id;
  }

  /// Resolves seeded `{'ar': ..., 'en': ...}` text for the current language,
  /// mimicking the API honouring `Accept-Language`.
  String tr(Object? text) {
    if (text is Map) return (text[languageCode()] ?? text['en']) as String;
    return text as String;
  }

  Never notFound([String message = 'Not found']) =>
      throw ServerException(statusCode: 404, message: message);

  Never badRequest(String message) =>
      throw ServerException(statusCode: 400, message: message);
}
