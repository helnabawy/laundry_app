import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/driver_task.dart';
import '../utils/category_icons.dart';

/// One stop in the driver's day, printed as a tag row.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final DriverTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);
    final order = task.order;

    return TagRow(
      serial: l10n.orderNumber(order.number.toString()),
      window: format.timeRange(task.slot.start, task.slot.end),
      title: '${task.address.area}${l10n.listSeparator}${task.address.city}',
      subtitle: order.servicesLabel,
      leading: CareGlyphIcon(
        categoryGlyph(order.leadCategoryId),
        color: colors.ink,
        size: 26,
        // One dot standard, two VIP: the level is read off the modifier.
        dots: order.tier.isVip ? 2 : 1,
      ),
      stamp: order.tier.isVip
          ? const StatusStamp(
              label: 'VIP',
              tone: StampTone.field,
              compact: true,
            )
          : null,
      onTap: onTap,
    );
  }
}
