import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../error/exceptions.dart';
import '../monitoring/app_reporter.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../router/routes.dart';
import '../sync/refresh_bus.dart';
import 'local_notifications.dart';

/// Push notifications through Firebase Cloud Messaging.
///
/// - Registers this install's token with the API after sign-in, and removes
///   it before sign-out, so pushes follow the account, not the phone.
/// - Order pushes (`data.type == 'order'`) refresh the screens showing that
///   order via [RefreshBus], and open it when tapped. One that arrives while
///   the app is open still shows as a system notification: iOS shows it
///   itself, Android through [LocalNotifications].
/// - Customers follow their laundry's topic; a silent `catalogue` message
///   there refetches prices while the shop is open.
///
/// Stays off — every method a no-op — when Firebase didn't start (mock mode,
/// an unsupported platform; see `initFirebase`), so local development needs
/// no setup.
class PushService {
  PushService({
    required ApiClient api,
    required RefreshBus refreshBus,
    LocalNotifications? localNotifications,
    AppReporter reporter = const NoopReporter(),
  }) : _api = api,
       _bus = refreshBus,
       _local = localNotifications,
       _reporter = reporter;

  final ApiClient _api;
  final RefreshBus _bus;

  /// Android only; null on iOS, which shows foreground pushes itself.
  final LocalNotifications? _local;
  final AppReporter _reporter;

  bool _enabled = false;
  bool _isDriver = false;
  String? _token;
  String? _topic;
  String? _wantedTopic;
  StreamSubscription<String>? _tokenRefresh;

  final _opened = StreamController<String>.broadcast();
  Map<String, dynamic>? _launchData;

  bool get enabled => _enabled;

  /// Routes to open because a push was tapped.
  Stream<String> get openedRoutes => _opened.stream;

  /// The route of the push that launched the app, once; then null. Asked
  /// after sign-in, when the role is known.
  String? takeLaunchRoute() {
    final data = _launchData;
    _launchData = null;
    return data == null ? null : routeFor(data, isDriver: _isDriver);
  }

  /// [firebaseReady]: whether `initFirebase` succeeded. [channelName] and
  /// [channelDescription] label the Android notification channel in system
  /// settings, in the app's language.
  Future<void> init({
    required bool firebaseReady,
    String channelName = LocalNotifications.channelId,
    String channelDescription = '',
  }) async {
    if (!firebaseReady) return;
    _enabled = true;
    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // iOS shows the system banner in the foreground too; Android doesn't, so
    // the app posts its own (see [LocalNotifications]).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onTapped(m.data));
    final launch = await messaging.getInitialMessage();
    _launchData = launch?.data;

    final local = _local;
    if (local == null) return;
    try {
      final localLaunch = await local.init(
        channelName: channelName,
        channelDescription: channelDescription,
      );
      _launchData ??= localLaunch;
      local.taps.listen(onTapped);
    } on Object catch (e, stack) {
      _failed('local notifications init', e, stack);
    }
  }

  /// After sign-in (or a restored session): ask permission, then register.
  Future<void> register({required bool isDriver}) async {
    _isDriver = isDriver;
    if (!_enabled) return;
    final messaging = FirebaseMessaging.instance;
    // Listen first: a token that only arrives later still gets uploaded.
    await _tokenRefresh?.cancel();
    _tokenRefresh = messaging.onTokenRefresh.listen(_onToken);
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // On iOS the FCM token needs the APNs token, which arrives a moment
      // after permission is granted.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var apns = await messaging.getAPNSToken();
        for (var i = 0; i < 10 && apns == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          apns = await messaging.getAPNSToken();
        }
        // Never arrives on a simulator; on a phone, it may come later and
        // [onTokenRefresh] uploads the FCM token then. Asking for the FCM
        // token without it throws.
        if (apns == null) {
          _reporter.log('push: no APNs token yet, FCM token deferred');
          return;
        }
      }
      final token = await messaging.getToken();
      if (token != null) await _onToken(token);
    } on Object catch (e, stack) {
      _failed('push register', e, stack);
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
    } on Object catch (e, stack) {
      _failed('push unregister', e, stack);
    }
  }

  /// Follow [laundryId]'s catalogue updates (null: follow none). Applied as
  /// soon as this install has a push token.
  Future<void> followLaundry(String? laundryId) async {
    _wantedTopic = laundryId == null ? null : laundryTopic(laundryId);
    if (!_enabled || _token == null) return;
    await _applyTopic();
  }

  Future<void> _applyTopic() async {
    final topic = _wantedTopic;
    if (topic == _topic) return;
    final messaging = FirebaseMessaging.instance;
    try {
      if (_topic case final old?) await messaging.unsubscribeFromTopic(old);
      if (topic != null) await messaging.subscribeToTopic(topic);
      _topic = topic;
    } on Object catch (e, stack) {
      _failed('push topic change to $topic', e, stack);
    }
  }

  Future<void> _onToken(String token) async {
    await _send(token);
    await _applyTopic();
  }

  Future<void> _send(String token) async {
    _token = token;
    try {
      await _api.post(
        ApiEndpoints.devices,
        data: {'token': token, 'platform': _platform},
      );
    } on Object catch (e, stack) {
      _failed('push token upload', e, stack);
    }
  }

  /// API failures were already reported by the HTTP layer; only the rest
  /// (Firebase, platform) is reported here.
  void _failed(String what, Object error, StackTrace stack) {
    if (error is ServerException ||
        error is NetworkException ||
        error is UnauthorizedException) {
      _reporter.log('$what failed: $error');
    } else {
      _reporter.recordError(error, stack, reason: what);
    }
  }

  /// A push that arrived while the app is open: refresh what it's about and,
  /// on Android, show it (iOS already did).
  @visibleForTesting
  Future<void> onForegroundMessage(RemoteMessage message) async {
    _reporter.log('push received', data: {'type': message.data['type']});
    _signal(message.data);
    final notification = message.notification;
    if (notification == null) return; // silent catalogue ping
    try {
      await _local?.show(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: message.data,
      );
    } on Object catch (e, stack) {
      _failed('local notification', e, stack);
    }
  }

  /// A notification — from FCM or [LocalNotifications] — was tapped.
  @visibleForTesting
  void onTapped(Map<String, dynamic> data) {
    _reporter.log('push opened', data: {'type': data['type']});
    _signal(data);
    if (routeFor(data, isDriver: _isDriver) case final route?) {
      _opened.add(route);
    }
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

/// Runs in its own isolate for pushes that arrive while the app is in the
/// background or closed. Nothing to do: the system shows notification
/// messages itself, and a silent catalogue ping doesn't matter while closed —
/// the app refetches when it opens. Registering it keeps data-only messages
/// from being dropped with a warning.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

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
