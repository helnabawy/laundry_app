/// Where crash data goes. Implemented per vendor (`firebase/`) and for the
/// console; only [DefaultAppReporter] talks to it.
abstract interface class CrashReporter {
  Future<void> log(String line);

  /// [value] is a String, num or bool; '' clears the key.
  Future<void> setKey(String key, Object value);

  Future<void> setUserId(String id);

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  });
}

/// Where analytics go. Never receives personal data.
abstract interface class AnalyticsTracker {
  Future<void> logEvent(String name, Map<String, Object> params);

  Future<void> logScreen(String name);

  Future<void> setUserId(String? id);

  Future<void> setUserProperty(String name, String? value);
}
