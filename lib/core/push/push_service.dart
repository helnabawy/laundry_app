import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../router/routes.dart';
import '../sync/refresh_bus.dart';

/// A push the app received while open, for an in-app banner.
typedef ForegroundPush = ({String title, String body, String? route});

/// Push notifications through Firebase Cloud Messaging.
///
/// - Registers this install's token with the API after sign-in, and removes
///   it before sign-out, so pushes follow the account, not the phone.
/// - Order pushes (`data.type == 'order'`) refresh the screens showing that
///   order via [RefreshBus], and open it when tapped.
/// - Customers follow their laundry's topic; a silent `catalogue` message
///   there refetches prices while the shop is open.
///
/// Stays off — every method a no-op — in mock mode or when Firebase fails to
/// start (e.g. an unsupported platform), so local development needs no setup.
class PushService {
  PushService({required ApiClient api, required RefreshBus refreshBus})
    : _api = api,
      _bus = refreshBus;

  final ApiClient _api;
  final RefreshBus _bus;

  bool _enabled = false;
  bool _isDriver = false;
  String? _token;
  String? _topic;
  StreamSubscription<String>? _tokenRefresh;

  final _foreground = StreamController<ForegroundPush>.broadcast();
  final _opened = StreamController<String>.broadcast();
  Map<String, dynamic>? _launchData;

  bool get enabled => _enabled;

  /// Pushes that arrived while the app was in the foreground.
  Stream<ForegroundPush> get foregroundPushes => _foreground.stream;

  /// Routes to open because a push was tapped.
  Stream<String> get openedRoutes => _opened.stream;

  /// The route of the push that launched the app, once; then null. Asked
  /// after sign-in, when the role is known.
  String? takeLaunchRoute() {
    final data = _launchData;
    _launchData = null;
    return data == null ? null : routeFor(data, isDriver: _isDriver);
  }

  Future<void> init() async {
    if (AppConfig.useMockApi) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on Object catch (e) {
      debugPrint('[push] Firebase not configured, push disabled: $e');
      return;
    }
    _enabled = true;
    final messaging = FirebaseMessaging.instance;
    // iOS shows the system banner in the foreground too; Android doesn't, so
    // the app shows its own (see [foregroundPushes]).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _signal(message.data);
      if (routeFor(message.data, isDriver: _isDriver) case final route?) {
        _opened.add(route);
      }
    });
    final launch = await messaging.getInitialMessage();
    _launchData = launch?.data;
  }

  /// After sign-in (or a restored session): ask permission, then register.
  Future<void> register({required bool isDriver}) async {
    _isDriver = isDriver;
    if (!_enabled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await _send(token);
      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen(_send);
    } on Object catch (e) {
      // e.g. iOS before the APNs token arrives; the refresh stream retries.
      debugPrint('[push] register failed: $e');
    }
  }

  /// Before sign-out, while the session can still authenticate the call.
  Future<void> unregister() async {
    if (!_enabled) return;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    await followLaundry(null);
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _api.delete(ApiEndpoints.devices, data: {'token': token});
    } on Object catch (e) {
      debugPrint('[push] unregister failed: $e');
    }
  }

  /// Follow [laundryId]'s catalogue updates (null: follow none).
  Future<void> followLaundry(String? laundryId) async {
    if (!_enabled) return;
    final topic = laundryId == null ? null : laundryTopic(laundryId);
    if (topic == _topic) return;
    final messaging = FirebaseMessaging.instance;
    try {
      if (_topic case final old?) await messaging.unsubscribeFromTopic(old);
      if (topic != null) await messaging.subscribeToTopic(topic);
      _topic = topic;
    } on Object catch (e) {
      debugPrint('[push] topic change failed: $e');
    }
  }

  Future<void> _send(String token) async {
    _token = token;
    try {
      await _api.post(
        ApiEndpoints.devices,
        data: {'token': token, 'platform': _platform},
      );
    } on Object catch (e) {
      debugPrint('[push] token upload failed: $e');
    }
  }

  void _onMessage(RemoteMessage message) {
    _signal(message.data);
    final notification = message.notification;
    if (notification == null) return; // silent catalogue ping
    _foreground.add((
      title: notification.title ?? '',
      body: notification.body ?? '',
      route: routeFor(message.data, isDriver: _isDriver),
    ));
  }

  void _signal(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'order':
        if (data['orderId'] case final String id) {
          _bus.publish(OrderChanged(id));
        }
      case 'catalogue':
        _bus.publish(const CatalogueChanged());
    }
  }

  static String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'web',
  };
}

/// The FCM topic for a laundry — must match laundry_admin's `vendorTopic()`
/// (`src/domain/push-copy.ts`).
String laundryTopic(String laundryId) =>
    'vendor-${laundryId.replaceAll(RegExp(r'[^a-zA-Z0-9_.~%-]'), '_')}';

/// Where tapping an order push should land, or null for non-order pushes.
@visibleForTesting
String? routeFor(Map<String, dynamic> data, {required bool isDriver}) {
  if (data['type'] != 'order') return null;
  final orderId = data['orderId'];
  if (orderId is! String || orderId.isEmpty) return null;
  if (!isDriver) return Routes.orderDetail(orderId);
  return switch (data['kind']) {
    'newPickup' => Routes.driverPickup(orderId),
    'newDelivery' => Routes.driverDelivery(orderId),
    _ => Routes.driverHome,
  };
}
