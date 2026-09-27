import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.notifications = const [],
    this.loading = true,
    this.failure,
  });

  /// Newest first.
  final List<AppNotification> notifications;
  final bool loading;
  final Failure? failure;

  int get unreadCount => notifications.where((n) => !n.read).length;

  @override
  List<Object?> get props => [notifications, loading, failure];
}

/// Backs both the bell (its unread count) and the inbox itself.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._getNotifications, this._markAllRead)
    : super(const NotificationsState());

  final GetNotifications _getNotifications;
  final MarkAllNotificationsRead _markAllRead;

  Future<void> load() async {
    emit(NotificationsState(notifications: state.notifications));
    final result = await _getNotifications();
    emit(
      result.fold(
        onErr: (f) => NotificationsState(
          notifications: state.notifications,
          loading: false,
          failure: f,
        ),
        onOk: (list) => NotificationsState(notifications: list, loading: false),
      ),
    );
  }

  /// Opening the inbox reads everything in it. The rows keep their unread
  /// marks for this visit, so the customer can still see what was new.
  Future<void> openInbox() async {
    await load();
    if (state.failure == null && state.unreadCount > 0) await _markAllRead();
  }
}
