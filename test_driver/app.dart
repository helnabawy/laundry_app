import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'package:laundry_app/app.dart';
import 'package:laundry_app/core/di/injection.dart';

/// Development entrypoint that exposes the Flutter Driver extension, so the
/// running app can be driven for screenshots and integration checks.
/// `lib/main.dart` stays the shipping entrypoint and never imports this, and
/// living under `test_driver/` keeps `flutter_driver` out of the app's
/// dependency graph.
Future<void> main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const LaundryApp());
}
