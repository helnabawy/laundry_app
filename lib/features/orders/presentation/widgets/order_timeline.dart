import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/order_status.dart';

/// The order's history, read down the label.
///
/// A fixed set of milestones — not every status. `awaitingPayment` is carried
/// by the invoice block instead, and `driverAssigned` is quick enough to fold
/// into "Order placed". A shop-flow order (`order.lines.isEmpty` — price
/// already fixed at checkout) uses a shorter set that skips the facility
/// inspection/payment wait, but still shows the items being washed.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final LaundryOrder order;

  static const _wizardMilestones = [
    OrderStatus.driverAssigned,
    OrderStatus.pickedUp,
    OrderStatus.atFacility,
    OrderStatus.processing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const _shopMilestones = [
    OrderStatus.driverAssigned,
    OrderStatus.pickedUp,
    OrderStatus.processing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  String _label(AppLocalizations l10n, OrderStatus status) => switch (status) {
    OrderStatus.driverAssigned => l10n.timelineDriverAssigned,
    OrderStatus.pickedUp => l10n.timelinePickedUp,
    OrderStatus.atFacility => l10n.timelineAtFacility,
    OrderStatus.processing => l10n.statusProcessing,
    OrderStatus.outForDelivery => l10n.statusOutForDelivery,
    OrderStatus.delivered => l10n.statusDelivered,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final milestones = order.lines.isEmpty
        ? _shopMilestones
        : _wizardMilestones;
    final reachedIndex = reachedMilestone(order, milestones);
    final isFailure =
        order.status.isFailure || order.status == OrderStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Entry(
          label: l10n.timelineCreated,
          time: format.dayAndTime(order.createdAt),
          state: _EntryState.done,
          isFirst: true,
        ),
        for (var i = 0; i < milestones.length; i++)
          _Entry(
            label: _label(l10n, milestones[i]),
            time: order.timeOf(milestones[i]) != null
                ? format.dayAndTime(order.timeOf(milestones[i])!)
                : null,
            state: isFailure && i >= reachedIndex
                ? _EntryState.upcoming
                : i < reachedIndex
                ? _EntryState.done
                : i == reachedIndex
                ? _EntryState.current
                : _EntryState.upcoming,
            isLast: i == milestones.length - 1,
          ),
      ],
    );
  }
}

/// The furthest milestone the order has actually reached, or -1 before the
/// first. Read from the order's history rather than its status alone, since
/// some statuses aren't milestones: while the laundry waits for payment
/// (`awaitingPayment`) the order is still "At the laundry", and a failed
/// stop leaves the order at the step it failed after.
@visibleForTesting
int reachedMilestone(LaundryOrder order, List<OrderStatus> milestones) {
  var reached = milestones.indexOf(order.status);
  for (var i = reached + 1; i < milestones.length; i++) {
    if (order.timeOf(milestones[i]) != null) reached = i;
  }
  return reached;
}

enum _EntryState { done, current, upcoming }

/// One line of the record: a mark, a rule running to the next, the label and
/// the time in its own tabular slot.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.label,
    required this.time,
    required this.state,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String? time;
  final _EntryState state;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final reached = state != _EntryState.upcoming;
    final ink = reached ? colors.ink : colors.inkTertiary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                SizedBox(
                  height: 9,
                  child: isFirst
                      ? null
                      : VerticalDivider(
                          color: reached ? colors.ink : colors.rule,
                          thickness: DesignRule.medium,
                          width: 18,
                        ),
                ),
                _Mark(state: state),
                if (!isLast)
                  Expanded(
                    child: VerticalDivider(
                      color: state == _EntryState.done
                          ? colors.ink
                          : colors.rule,
                      thickness: DesignRule.medium,
                      width: 18,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: DesignSpace.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.bodyLarge?.copyWith(
                      color: ink,
                      fontWeight: state == _EntryState.current
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (time case final stamped?) ...[
                    const SizedBox(height: DesignSpace.xxs),
                    Text(
                      stamped,
                      style: DesignTypography.fibreLine(colors.inkTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Done is a filled square with a bar under it; current is a filled square;
/// upcoming is an open one. State reads by form before it reads by colour.
class _Mark extends StatelessWidget {
  const _Mark({required this.state});

  final _EntryState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = state != _EntryState.upcoming;
    return SizedBox(
      width: 14,
      height: 16,
      child: Column(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: filled ? colors.ink : const Color(0x00000000),
              border: Border.all(
                color: filled ? colors.ink : colors.ruleStrong,
                width: DesignRule.medium,
              ),
            ),
          ),
          if (state == _EntryState.done) ...[
            const SizedBox(height: 2),
            Container(width: 11, height: DesignRule.medium, color: colors.ink),
          ],
        ],
      ),
    );
  }
}
