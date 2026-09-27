import '../../../../core/result/result.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  /// Everything sent to the signed-in user about their orders (a customer)
  /// or their stops (a driver), newest first.
  Future<Result<List<AppNotification>>> getNotifications();

  Future<Result<void>> markAllRead();
}
