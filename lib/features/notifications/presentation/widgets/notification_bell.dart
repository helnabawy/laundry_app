import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../cubit/notifications_cubit.dart';

/// The bell as either role's shell uses it: reads the unread count from the
/// shell's [NotificationsCubit], opens the inbox, and re-reads on the way
/// back (the inbox marked everything read).
class OpenNotificationsBell extends StatelessWidget {
  const OpenNotificationsBell({super.key, this.color, this.ground});

  final Color? color;
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsCubit, int>(
      (c) => c.state.unreadCount,
    );
    return NotificationBell(
      unreadCount: unread,
      color: color,
      ground: ground,
      onPressed: () async {
        final cubit = context.read<NotificationsCubit>();
        await context.push(Routes.notifications);
        await cubit.load();
      },
    );
  }
}

/// The way into the inbox, for either role's top bar.
///
/// With something new the bell fills — the grammar's "active" — and carries
/// the unread count in a squared ink slot. No red: nothing has failed.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.unreadCount,
    required this.onPressed,
    this.color,
    this.ground,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  /// The bell's ink; defaults to the page ink.
  final Color? color;

  /// What the bell sits on, used to cut the badge free of the bell stroke.
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final ink = color ?? colors.ink;
    final hasUnread = unreadCount > 0;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: hasUnread
          ? l10n.notificationsUnreadLabel(unreadCount)
          : l10n.notifications,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: DesignSpace.touchTarget,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                hasUnread ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
                color: ink,
                size: 24,
              ),
              if (hasUnread)
                PositionedDirectional(
                  top: 5,
                  end: 3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.ink,
                      borderRadius: BorderRadius.circular(DesignRadius.slot),
                      border: Border.all(
                        color: ground ?? colors.tape,
                        width: DesignRule.medium,
                      ),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      textScaler: TextScaler.noScaling,
                      style: DesignTypography.numeric(
                        colors.onInk,
                        size: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
