import 'package:laundry_app/core/monitoring/app_reporter.dart';

/// An [AppReporter] that remembers what it was told, for asserting on
/// analytics events and reported errors.
class RecordingReporter implements AppReporter {
  final logs = <String>[];
  final errors = <({Object error, String? reason, RequestContext? request})>[];
  final events = <AnalyticsEvent>[];
  final screens = <String>[];
  final context = <String, Object?>{};
  UserContext? user;

  List<String> get eventNames => [for (final e in events) e.name];

  @override
  void log(String message, {Map<String, Object?>? data}) => logs.add(message);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    RequestContext? request,
    Map<String, Object?>? extra,
  }) async => errors.add((error: error, reason: reason, request: request));

  @override
  void track(AnalyticsEvent event) => events.add(event);

  @override
  void screen(String name, {Map<String, Object?>? params}) => screens.add(name);

  @override
  void setUser(UserContext? user) => this.user = user;

  @override
  void setContext(String key, Object? value) => context[key] = value;
}
