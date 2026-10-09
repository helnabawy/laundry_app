import 'package:flutter/widgets.dart';

import 'app_reporter.dart';

/// Reports each screen the user lands on and leaves a breadcrumb for every
/// push and pop, so a crash report shows the path that led to it.
///
/// go_router names its pages after the route path (`/orders/:id`,
/// `invoice`) and passes the path parameters as arguments; dialogs and
/// sheets are named after their route type.
class MonitoringRouteObserver extends NavigatorObserver {
  MonitoringRouteObserver(this._reporter);

  final AppReporter _reporter;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reporter.log('push ${screenName(route)}');
    _show(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reporter.log('pop ${screenName(route)}');
    if (previousRoute != null) _show(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _reporter.log(
      'replace ${oldRoute == null ? '-' : screenName(oldRoute)}'
      ' → ${newRoute == null ? '-' : screenName(newRoute)}',
    );
    if (newRoute != null) _show(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _reporter.log('remove ${screenName(route)}');

  void _show(Route<dynamic> route) {
    // Popups (dialogs, sheets, menus) are breadcrumbs, not screens.
    if (route is! PageRoute) return;
    _reporter.screen(screenName(route), params: _params(route));
  }

  static Map<String, Object?>? _params(Route<dynamic> route) =>
      switch (route.settings.arguments) {
        final Map<Object?, Object?> args when args.isNotEmpty => {
          for (final MapEntry(:key, :value) in args.entries) '$key': value,
        },
        _ => null,
      };

  @visibleForTesting
  static String screenName(Route<dynamic> route) =>
      switch (route.settings.name) {
        final name? when name.isNotEmpty => name,
        _ => route.runtimeType.toString().split('<').first,
      };
}
