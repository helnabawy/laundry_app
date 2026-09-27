import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/app_notification.dart';
import '../models/app_notification_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAllRead();
}

class NotificationApiDataSource implements NotificationRemoteDataSource {
  const NotificationApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final json = await _api.get(ApiEndpoints.notifications) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
  }

  @override
  Future<void> markAllRead() => _api.post(ApiEndpoints.notificationsReadAll);
}
