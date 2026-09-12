/// Build-time configuration, overridable with `--dart-define`.
///
/// ```bash
/// flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://api.example.com
/// ```
abstract final class AppConfig {
  /// When true the app runs against the in-memory mock backend
  /// (default until the ASP.NET Core API from Phase 1 is deployed).
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  /// Base URL of the ASP.NET Core API. `10.0.2.2` is the host machine as
  /// seen from the Android emulator.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );

  /// UAE only for the MVP.
  static const String countryDialCode = '+971';

  static const int otpLength = 4;
  static const int otpResendSeconds = 60;

  static const List<String> supportedLanguageCodes = ['ar', 'en'];
}
