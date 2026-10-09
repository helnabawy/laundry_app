import 'analytics_event.dart';
import 'report_context.dart';

export 'analytics_event.dart';
export 'report_context.dart';

/// Crash reporting, logging and analytics behind one interface — the only
/// monitoring type features depend on. The vendor (Firebase today) lives in
/// `monitoring/firebase/` and is chosen in the composition root.
///
/// Every error recorded carries who is signed in ([setUser]), the app state
/// ([setContext]), the recent trail of logs, screens and requests ([log]),
/// and the failing request, when there was one.
abstract interface class AppReporter {
  /// A breadcrumb: kept in the trail attached to the next error.
  void log(String message, {Map<String, Object?>? data});

  /// A handled (or, with [fatal], an unhandled) error.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    RequestContext? request,
    Map<String, Object?>? extra,
  });

  /// A product analytics event.
  void track(AnalyticsEvent event);

  /// The screen now on top.
  void screen(String name, {Map<String, Object?>? params});

  /// Who is signed in; null on sign-out.
  void setUser(UserContext? user);

  /// App state attached to every report (e.g. `laundry_id`, `locale`).
  /// A null [value] clears it.
  void setContext(String key, Object? value);
}

/// Reports nothing. The default for cubits built outside DI (tests).
class NoopReporter implements AppReporter {
  const NoopReporter();

  @override
  void log(String message, {Map<String, Object?>? data}) {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    RequestContext? request,
    Map<String, Object?>? extra,
  }) async {}

  @override
  void track(AnalyticsEvent event) {}

  @override
  void screen(String name, {Map<String, Object?>? params}) {}

  @override
  void setUser(UserContext? user) {}

  @override
  void setContext(String key, Object? value) {}
}
