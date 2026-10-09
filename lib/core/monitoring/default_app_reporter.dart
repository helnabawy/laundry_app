import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_reporter.dart';
import 'breadcrumbs.dart';
import 'sinks.dart';

/// [AppReporter] over a [CrashReporter] and an [AnalyticsTracker].
///
/// Keeps the user, the app context and a breadcrumb trail, and attaches them
/// all to every error. Analytics only receives what is safe to share: the
/// user id, role and a few app-state properties — never phone or name.
class DefaultAppReporter implements AppReporter {
  DefaultAppReporter({
    required CrashReporter crash,
    required AnalyticsTracker analytics,
    Breadcrumbs? breadcrumbs,
  }) : _crash = crash,
       _analytics = analytics,
       _breadcrumbs = breadcrumbs ?? Breadcrumbs();

  final CrashReporter _crash;
  final AnalyticsTracker _analytics;
  final Breadcrumbs _breadcrumbs;

  /// Context keys mirrored to analytics as user properties.
  static const analyticsProperties = {'laundry_id', 'locale', 'theme'};

  final _context = <String, Object?>{};
  UserContext? _user;

  UserContext? get user => _user;
  Map<String, Object?> get context => Map.unmodifiable(_context);
  List<String> get trail => _breadcrumbs.lines;

  @override
  void log(String message, {Map<String, Object?>? data}) {
    final text = data == null || data.isEmpty
        ? message
        : '$message ${describe(data, max: 300)}';
    final line = _breadcrumbs.add(text);
    _run(() => _crash.log(line));
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    RequestContext? request,
    Map<String, Object?>? extra,
  }) async {
    try {
      if (request != null) _breadcrumbs.add('✗ ${request.summary}');
      await _setKeys(request?.toKeys() ?? const {});
      await _crash.setKey(
        'breadcrumbs',
        _breadcrumbs.tail(maxReportValueLength),
      );
      await _crash.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
        information: [
          if (extra != null && extra.isNotEmpty) 'extra: ${describe(extra)}',
          if (request != null) 'request: ${request.summary}',
        ],
      );
    } on Object catch (e) {
      debugPrint('[monitor] recordError failed: $e');
    } finally {
      // Request keys describe this error only; don't let them stick to the
      // next one.
      if (request != null) {
        await _run(() async {
          for (final key in RequestContext.keys) {
            await _crash.setKey(key, '');
          }
        });
      }
    }
  }

  @override
  void track(AnalyticsEvent event) {
    _breadcrumbs.add('event ${event.name}');
    _run(() => _analytics.logEvent(event.name, event.params));
  }

  @override
  void screen(String name, {Map<String, Object?>? params}) {
    final previous = _context['current_route'];
    log('screen $name', data: params);
    setContext('previous_route', previous);
    setContext('current_route', name);
    _run(() => _analytics.logScreen(name));
  }

  @override
  void setUser(UserContext? user) {
    _user = user;
    log(user == null ? 'signed out' : 'signed in as ${user.role} ${user.id}');
    _run(() async {
      await _crash.setUserId(user?.id ?? '');
      await _setKeys(
        user?.toKeys() ?? {for (final k in UserContext.keys) k: null},
      );
      await _analytics.setUserId(user?.id);
      await _analytics.setUserProperty('role', user?.role);
    });
  }

  @override
  void setContext(String key, Object? value) {
    if (_context[key] == value) return;
    if (value == null) {
      _context.remove(key);
    } else {
      _context[key] = value;
    }
    _run(() async {
      await _crash.setKey(key, _keyValue(value));
      if (analyticsProperties.contains(key)) {
        await _analytics.setUserProperty(key, value?.toString());
      }
    });
  }

  Future<void> _setKeys(Map<String, Object?> keys) async {
    for (final MapEntry(:key, :value) in keys.entries) {
      await _crash.setKey(key, _keyValue(value));
    }
  }

  static Object _keyValue(Object? value) => switch (value) {
    null => '',
    num() || bool() => value,
    _ => truncate(value.toString()),
  };

  /// Monitoring never breaks the app.
  Future<void> _run(Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (e) {
      debugPrint('[monitor] $e');
    }
  }
}
