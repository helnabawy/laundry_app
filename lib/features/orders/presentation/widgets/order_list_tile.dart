import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/laundry_order.dart';

/// A compact order row, in the one label anatomy: serial, service, window.
class OrderListTile extends StatelessWidget {
  const OrderListTile({super.key, required this.order, required this.onTap});

  final LaundryOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);
    return LabelRow(
      title: l10n.orderNumber(order.number.toString()),
      subtitle: '${order.servicesLabel} · ${order.tier.name}',
      value: order.invoice != null ? format.money(order.invoice!.total) : null,
      trailing: Icon(CupertinoIcons.chevron_forward, color: colors.inkTertiary),
      onTap: onTap,
    );
  }
}

/// What the hero band does not carry: the amount slot held open until the
/// facility prices the order, and the way through to tracking.
class CurrentOrderDetail extends StatelessWidget {
  const CurrentOrderDetail({
    super.key,
    required this.order,
    required this.onTap,
  });

  final LaundryOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSpace.gutter,
        DesignSpace.xl,
        DesignSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountSlot(
            label: l10n.total,
            placeholder: l10n.currencyAed('\u2014.\u2014\u2014'),
            amount: order.invoice != null
                ? format.money(order.invoice!.total)
                : null,
            pendingNote: l10n.finalPriceBody,
          ),
          const SizedBox(height: DesignSpace.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.deliveryAt(
                    format.slotRelative(
                      order.deliverySlot.start,
                      order.deliverySlot.end,
                    ),
                  ),
                  style: text.bodySmall?.copyWith(color: colors.inkSecondary),
                ),
              ),
              const SizedBox(width: DesignSpace.md),
              TintAction(
                label: l10n.track,
                onPressed: onTap,
                trailing: const Icon(CupertinoIcons.chevron_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
