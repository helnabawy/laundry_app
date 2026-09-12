import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies GoRouter to re-run its redirect whenever any stream emits.
class StreamRefreshListenable extends ChangeNotifier {
  StreamRefreshListenable(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final stream in streams) stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
