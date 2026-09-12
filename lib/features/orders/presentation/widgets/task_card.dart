import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/labeled_rows.dart';
import '../../domain/entities/driver_task.dart';

/// One row in the driver's today list (plan §8.2 "مهام اليوم").
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final DriverTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final text = Theme.of(context).textTheme;
    final order = task.order;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.orderNumber(order.number.toString()),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Pill(
                label: format.timeRange(task.slot.start, task.slot.end),
                foreground: AppColors.ink,
                background: AppColors.background,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${task.address.area}، ${task.address.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (order.tier.isVip)
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 8),
                  child: Pill(
                    label: 'VIP',
                    foreground: AppColors.gold,
                    background: AppColors.goldSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${order.category.name} · ${order.subService.name}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onTap, child: Text(l10n.viewDetails)),
          ),
        ],
      ),
    );
  }
}
