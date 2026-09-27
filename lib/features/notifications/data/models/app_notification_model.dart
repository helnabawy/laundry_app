import '../../domain/entities/app_notification.dart';

abstract final class AppNotificationModel {
  static AppNotification fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    kind: NotificationKind.fromJson(json['kind'] as String),
    orderId: json['orderId'] as String,
    orderNumber: json['orderNumber'] as int,
    sentAt: DateTime.parse(json['sentAt'] as String),
    read: json['read'] as bool? ?? false,
  );
}
