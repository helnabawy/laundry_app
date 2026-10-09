import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/monitoring/app_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  _reportUncaughtErrors(sl<AppReporter>());
  runApp(const LaundryApp());
}

/// Framework errors (build, layout, paint) and uncaught async errors go to
/// the reporter as fatal, with the user, screen trail and app state.
void _reportUncaughtErrors(AppReporter reporter) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.recordError(
      details.exception,
      details.stack,
      reason: details.context?.toDescription() ?? details.library,
      fatal: true,
      extra: {'library': details.library},
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, reason: 'uncaught', fatal: true);
    return true;
  };
}
