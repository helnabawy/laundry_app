import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/laundry_order.dart';
import '../utils/order_status_x.dart';
import 'status_pill.dart';

/// A order row. [detailed] renders the bigger "current order" card from the
/// home screen (status pill, divider, delivery time + track button);
/// otherwise a compact row for order lists.
class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.order,
    required this.onTap,
    this.detailed = false,
  });

  final LaundryOrder order;
  final VoidCallback onTap;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final format = AppFormat.of(context);
    final summary =
        '${order.category.name} · ${order.subService.name} · ${order.tier.name}';

    if (!detailed) {
      return AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderNumber(order.number.toString()),
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.invoice != null
                      ? format.money(order.invoice!.total)
                      : '—',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  order.status.label(l10n),
                  style: text.bodySmall?.copyWith(color: order.status.tone.foreground),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OrderStatusPill(order.status),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.orderNumber(order.number.toString()),
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(summary, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.deliveryAt(format.slotRelative(
                    order.deliverySlot.start,
                    order.deliverySlot.end,
                  )),
                  style: text.bodyMedium,
                ),
              ),
              TextButton(onPressed: onTap, child: Text(l10n.track)),
            ],
          ),
        ],
      ),
    );
  }
}
