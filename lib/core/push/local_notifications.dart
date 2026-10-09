import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// System notifications the app posts itself, for pushes that arrive while
/// it's open — Android only: there FCM hands a foreground push to the app
/// without showing it. (iOS shows the system banner itself; see
/// `setForegroundNotificationPresentationOptions` in [PushService].)
///
/// A notification carries the push's `data` as its payload, so tapping it
/// routes exactly like tapping an FCM notification.
class LocalNotifications {
  LocalNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Must match laundry_admin's order pushes (`channelId`) and the
  /// `default_notification_channel_id` in AndroidManifest.xml.
  static const channelId = 'order_updates';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<Map<String, dynamic>>.broadcast();
  String _channelName = channelId;

  /// Push data of notifications tapped while the app was running.
  Stream<Map<String, dynamic>> get taps => _taps.stream;

  /// Creates (or renames) the channel and starts listening for taps. Returns
  /// the push data of the notification that launched the app, if any.
  Future<Map<String, dynamic>?> init({
    required String channelName,
    required String channelDescription,
  }) async {
    _channelName = channelName;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (decodePayload(response.payload) case final data?) _taps.add(data);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
          ),
        );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch == null || !launch.didNotificationLaunchApp) return null;
    return decodePayload(launch.notificationResponse?.payload);
  }

  /// Shows a heads-up notification. One per order: a newer status replaces
  /// the older one.
  Future<void> show({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) => _plugin.show(
    id: notificationId(data),
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode(data),
  );
}

/// The notification id for a push: the same for every push about one order.
int notificationId(Map<String, dynamic> data) =>
    (data['orderId'] ?? data['type'] ?? '').hashCode & 0x7fffffff;

/// Push data back from a notification payload; null if there's none.
Map<String, dynamic>? decodePayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final data = jsonDecode(payload);
    return data is Map<String, dynamic> ? data : null;
  } on FormatException {
    return null;
  }
}
