import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications implements UseCase<List<AppNotification>, NoParams> {
  const GetNotifications(this._repo);
  final NotificationRepository _repo;

  @override
  Future<Result<List<AppNotification>>> call([
    NoParams params = const NoParams(),
  ]) => _repo.getNotifications();
}

class MarkAllNotificationsRead implements UseCase<void, NoParams> {
  const MarkAllNotificationsRead(this._repo);
  final NotificationRepository _repo;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repo.markAllRead();
}
