import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';

/// Starts Firebase once for every service that uses it (push, crash
/// reporting, analytics). Returns false — and those services stay off — in
/// mock mode or where Firebase isn't configured, so local development needs
/// no setup.
Future<bool> initFirebase() async {
  if (AppConfig.useMockApi) return false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on Object catch (e) {
    debugPrint('[firebase] not configured, Firebase services off: $e');
    return false;
  }
}
