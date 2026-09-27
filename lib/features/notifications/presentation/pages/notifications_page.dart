import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../widgets/notification_row.dart';

/// Everything the app has told this person about their orders, newest first,
/// grouped by day. Opening it reads it; each entry leads back to its order.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..openInbox(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  /// Where an entry leads. A driver goes to the stop; a customer to the order.
  String? _destination(BuildContext context, AppNotification n) {
    final session = context.read<SessionCubit>().state;
    final isDriver =
        session is SessionAuthenticated && session.user.role == UserRole.driver;
    if (!isDriver) return Routes.orderDetail(n.orderId);
    return switch (n.kind) {
      NotificationKind.newPickup => Routes.driverPickup(n.orderId),
      NotificationKind.newDelivery => Routes.driverDelivery(n.orderId),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final Widget body;
        if (state.notifications.isEmpty) {
          body = state.loading
              ? const LoadingView()
              : state.failure != null
              ? ErrorView(
                  message: state.failure!.localized(l10n),
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<NotificationsCubit>().load(),
                )
              : EmptyView(
                  glyph: CareGlyph.custody,
                  message: l10n.noNotifications,
                  note: l10n.noNotificationsNote,
                );
        } else {
          final days = _byDay(state.notifications);
          body = RefreshIndicator(
            color: colors.ink,
            backgroundColor: colors.tape,
            onRefresh: () => context.read<NotificationsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: DesignSpace.huge),
              children: [
                for (final (day, entries) in days)
                  LabelGroup(
                    heading: _dayLabel(context, day),
                    children: [
                      for (final n in entries)
                        NotificationRow(
                          notification: n,
                          onTap: switch (_destination(context, n)) {
                            final route? => () => context.push(route),
                            null => null,
                          },
                        ),
                    ],
                  ),
              ],
            ),
          );
        }

        return DetailPage(title: l10n.notifications, child: body);
      },
    );
  }

  /// Consecutive runs of the same calendar day; the list is newest first.
  List<(DateTime, List<AppNotification>)> _byDay(List<AppNotification> all) {
    final days = <(DateTime, List<AppNotification>)>[];
    for (final n in all) {
      final day = DateUtils.dateOnly(n.sentAt);
      if (days.isNotEmpty && days.last.$1 == day) {
        days.last.$2.add(n);
      } else {
        days.add((day, [n]));
      }
    }
    return days;
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (today.difference(day).inDays) {
      0 => l10n.today,
      1 => l10n.yesterday,
      _ => '${format.weekday(day)} ${day.day} ${format.month(day)}',
    };
  }
}
