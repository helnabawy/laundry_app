import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/app_notification.dart';
import '../utils/notification_kind_x.dart';

/// One notification, in the label anatomy every list in the app uses: the
/// glyph on its fixed column, the event, what it means for this order, and
/// the time in its own slot.
///
/// Unread is carried by form, not colour: a square mark in the gutter (the
/// same mark the timeline uses for "reached") and a heavier title. The glyph
/// column never moves for it.
class NotificationRow extends StatefulWidget {
  const NotificationRow({super.key, required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  State<NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<NotificationRow> {
  var _down = false;

  static const _markSize = 7.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final n = widget.notification;
    final unread = !n.read;
    final title = n.kind.title(l10n);
    final body = n.kind.body(l10n, n.orderNumber);
    final time = AppFormat.of(context).time(n.sentAt);
    final tappable = widget.onTap != null;

    return Semantics(
      button: tappable,
      excludeSemantics: true,
      label: [if (unread) l10n.unread, title, body, time].join('. '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: tappable ? (_) => setState(() => _down = true) : null,
        onTapUp: tappable ? (_) => setState(() => _down = false) : null,
        onTapCancel: tappable ? () => setState(() => _down = false) : null,
        onTap: tappable
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: DesignMotion.quick,
          color: _down ? colors.tapeRecessed : const Color(0x00000000),
          constraints: const BoxConstraints(minHeight: DesignSpace.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSpace.gutter,
            vertical: DesignSpace.md,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (unread)
                PositionedDirectional(
                  // Centred in the gutter, level with the title's cap height.
                  start: -(DesignSpace.gutter + _markSize) / 2,
                  top: 7,
                  child: Container(
                    width: _markSize,
                    height: _markSize,
                    color: colors.ink,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: CareGlyphIcon(
                        n.kind.glyph,
                        color: colors.ink,
                        size: 26,
                        bars: n.kind.isComplete ? 1 : 0,
                        crossed: n.kind.isFailure,
                        crossColor: colors.signal,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: text.bodyLarge?.copyWith(
                                  color: colors.ink,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: DesignSpace.sm),
                            Text(
                              time,
                              style: DesignTypography.fibreLine(
                                unread ? colors.ink : colors.inkTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignSpace.xxs),
                        Text(
                          body,
                          style: text.bodySmall?.copyWith(
                            color: colors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
