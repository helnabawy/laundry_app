/// Build-time configuration, overridable with `--dart-define`.
///
/// ```bash
/// flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://api.example.com
/// ```
abstract final class AppConfig {
  /// When true the app runs against the in-memory mock backend
  /// (default until the ASP.NET Core API from Phase 1 is deployed).
  static const bool useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);

  /// seen from the Android emulator.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5080');

  /// UAE only for the MVP.
  static const String countryDialCode = '+971';

  static const int otpLength = 4;
  static const int otpResendSeconds = 60;

  static const List<String> supportedLanguageCodes = ['ar', 'en'];

  /// Map tiles for the address pin. OpenStreetMap's own servers are fine for
  /// development but not for production traffic — point this at a paid tile
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Sent as the tile request's User-Agent, as OSM's usage policy requires.
  static const String mapUserAgentPackage = 'com.laundryapp.laundry_app';

  /// Where the map opens when there is no pin and no GPS fix yet: central
  /// Abu Dhabi, where the service operates today.
  static const double mapDefaultLatitude = 24.4539;
  static const double mapDefaultLongitude = 54.3773;
}
