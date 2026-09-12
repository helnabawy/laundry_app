import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/order_status.dart';

/// Plan §8.1 "تتبع الطلب": a fixed set of milestones (not every status —
/// `awaitingPayment` is reflected by the invoice card instead, and
/// `driverAssigned` is quick enough to fold into "Order placed").
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final LaundryOrder order;

  static const _milestones = [
    OrderStatus.driverAssigned,
    OrderStatus.pickedUp,
    OrderStatus.atFacility,
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
    final reachedIndex = _milestones.indexOf(order.status);
    final isFailure = order.status.isFailure || order.status == OrderStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineRow(
          label: l10n.timelineCreated,
          time: format.dayAndTime(order.createdAt),
          state: _RowState.done,
          isFirst: true,
        ),
        for (var i = 0; i < _milestones.length; i++)
          _TimelineRow(
            label: _label(l10n, _milestones[i]),
            time: order.timeOf(_milestones[i]) != null
                ? format.dayAndTime(order.timeOf(_milestones[i])!)
                : null,
            state: isFailure && i >= reachedIndex
                ? _RowState.upcoming
                : i < reachedIndex
                ? _RowState.done
                : i == reachedIndex
                ? _RowState.current
                : _RowState.upcoming,
            isLast: i == _milestones.length - 1,
          ),
      ],
    );
  }
}

enum _RowState { done, current, upcoming }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.time,
    required this.state,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String? time;
  final _RowState state;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _RowState.done => AppColors.success,
      _RowState.current => AppColors.teal,
      _RowState.upcoming => AppColors.line,
    };
    final textColor = state == _RowState.upcoming ? AppColors.faint : AppColors.ink;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (!isFirst) SizedBox(height: 2, child: Container(width: 2, color: color)),
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == _RowState.upcoming ? Colors.white : color,
                  border: Border.all(color: color, width: 2),
                ),
                child: state == _RowState.done
                    ? const Icon(Icons.check, size: 9, color: Colors.white)
                    : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(time!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
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
