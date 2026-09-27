import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<Result<List<AppNotification>>> getNotifications() =>
      guard(_remote.getNotifications);

  @override
  Future<Result<void>> markAllRead() => guard(_remote.markAllRead);
}
