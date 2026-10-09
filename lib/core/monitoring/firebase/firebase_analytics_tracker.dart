import 'package:firebase_analytics/firebase_analytics.dart';

import '../sinks.dart';

/// [AnalyticsTracker] on Google Analytics for Firebase.
class FirebaseAnalyticsTracker implements AnalyticsTracker {
  FirebaseAnalyticsTracker([FirebaseAnalytics? analytics])
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) => _analytics
      .logEvent(name: name, parameters: params.isEmpty ? null : params);

  @override
  Future<void> logScreen(String name) =>
      _analytics.logScreenView(screenName: name, screenClass: name);

  @override
  Future<void> setUserId(String? id) => _analytics.setUserId(id: id);

  @override
  Future<void> setUserProperty(String name, String? value) =>
      _analytics.setUserProperty(name: name, value: value);
}
