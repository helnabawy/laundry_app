import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Something changed on the server (or may have, while the app was away),
/// so screens showing that data should refetch it.
sealed class RefreshSignal {
  const RefreshSignal();
}

/// An order moved — from a push notification. Screens about that order, and
/// lists that contain it, reload.
final class OrderChanged extends RefreshSignal {
  const OrderChanged(this.orderId);

  final String orderId;
}

/// The laundry edited its catalogue, prices, service levels or time slots.
final class CatalogueChanged extends RefreshSignal {
  const CatalogueChanged();
}

/// The app came back to the foreground; anything may be stale.
final class AppResumed extends RefreshSignal {
  const AppResumed();
}

/// App-wide fan-out of [RefreshSignal]s. Push messages and the app lifecycle
/// publish; cubits listen through [RefreshesOnSignal].
class RefreshBus {
  final _controller = StreamController<RefreshSignal>.broadcast();

  Stream<RefreshSignal> get signals => _controller.stream;

  void publish(RefreshSignal signal) => _controller.add(signal);
}

/// Lets a cubit reload itself when a matching [RefreshSignal] arrives, and
/// stops listening when the cubit closes.
mixin RefreshesOnSignal<S> on Cubit<S> {
  StreamSubscription<RefreshSignal>? _refreshSubscription;

  void refreshOn(
    RefreshBus? bus,
    bool Function(RefreshSignal signal) when,
    Future<void> Function() refresh,
  ) {
    _refreshSubscription?.cancel();
    _refreshSubscription = bus?.signals.where(when).listen((_) {
      if (!isClosed) refresh();
    });
  }

  @override
  Future<void> close() async {
    await _refreshSubscription?.cancel();
    return super.close();
  }
}

/// Publishes [AppResumed] when the app returns to the foreground after at
/// least [minAway], so a quick app switch doesn't refetch everything.
class AppResumeObserver with WidgetsBindingObserver {
  AppResumeObserver(this._bus, {this.minAway = const Duration(seconds: 30)});

  final RefreshBus _bus;
  final Duration minAway;
  DateTime? _pausedAt;

  void attach() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt != null &&
            DateTime.now().difference(pausedAt) >= minAway) {
          _bus.publish(const AppResumed());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }
}
