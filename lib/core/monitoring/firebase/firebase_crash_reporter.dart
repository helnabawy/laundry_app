import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../sinks.dart';

/// [CrashReporter] on Firebase Crashlytics. Collection is off in debug
/// builds so development crashes don't pollute the dashboard.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter([FirebaseCrashlytics? crashlytics])
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  Future<void> init() =>
      _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  @override
  Future<void> log(String line) => _crashlytics.log(line);

  @override
  Future<void> setKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  @override
  Future<void> setUserId(String id) => _crashlytics.setUserIdentifier(id);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) {
    // Collection is off in debug; keep errors visible in the console.
    if (kDebugMode) debugPrint('[monitor] $reason: $error\n$stack');
    return _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
      information: information,
    );
  }
}
