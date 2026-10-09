import 'package:flutter/foundation.dart';

import 'sinks.dart';

/// Prints errors and analytics to the debug console. Used when Firebase is
/// off: mock mode, tests, or a platform without a Firebase config.
///
/// Breadcrumb lines and keys stay quiet — Dio and the app already log
/// those — but are printed with an error, so it reads like a crash report.
class ConsoleCrashReporter implements CrashReporter {
  final _keys = <String, Object>{};
  final _log = <String>[];

  @override
  Future<void> log(String line) async {
    _log.add(line);
    if (_log.length > 100) _log.removeAt(0);
  }

  @override
  Future<void> setKey(String key, Object value) async {
    if (value == '') {
      _keys.remove(key);
    } else {
      _keys[key] = value;
    }
  }

  @override
  Future<void> setUserId(String id) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    if (!kDebugMode) return;
    final keys = {..._keys}..remove('breadcrumbs');
    debugPrint(
      [
        '[monitor] ${fatal ? 'FATAL' : 'error'}'
            '${reason == null ? '' : ' ($reason)'}: $error',
        for (final MapEntry(:key, :value) in keys.entries) '  $key: $value',
        ...information.map((i) => '  $i'),
        '  trail:',
        ..._log.reversed.take(15).toList().reversed.map((l) => '    $l'),
        if (stack != null) '$stack',
      ].join('\n'),
    );
  }
}

class ConsoleAnalyticsTracker implements AnalyticsTracker {
  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    if (kDebugMode) debugPrint('[analytics] $name $params');
  }

  @override
  Future<void> logScreen(String name) async {
    if (kDebugMode) debugPrint('[analytics] screen $name');
  }

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}
}
