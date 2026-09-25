import 'package:flutter/cupertino.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/task_failure.dart';

/// The in-app half of the "we couldn't collect" notification: why the driver
/// left without the items, that the order is cancelled, and the way to book a
/// new pickup time. The push itself is sent by the backend.
class PickupFailedNotice extends StatelessWidget {
  const PickupFailedNotice({
    super.key,
    required this.order,
    this.onReschedule,
    this.showNumber = false,
  });

  final LaundryOrder order;

  /// Null where the page already offers its own way to book again.
  final VoidCallback? onReschedule;

  /// On the home screen the notice stands alone, so it names the order.
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final failure = order.failure;
    final reason = switch (failure?.reason) {
      TaskFailureReason.customerAbsent => l10n.customerReasonAbsent,
      TaskFailureReason.wrongAddress => l10n.customerReasonWrongAddress,
      TaskFailureReason.customerRescheduled => l10n.customerReasonRescheduled,
      TaskFailureReason.other ||
      null => failure?.note ?? l10n.customerReasonOther,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoticeBlock(
          title: showNumber
              ? l10n.pickupFailedHomeTitle(order.number.toString())
              : l10n.pickupFailedCustomerTitle,
          message: l10n.pickupFailedCustomerBody(reason),
          tone: NoticeTone.caution,
          glyph: CareGlyphIcon(
            CareGlyph.collect,
            color: colors.signal,
            size: 22,
            crossed: true,
            crossColor: colors.signal,
          ),
        ),
        if (onReschedule case final reschedule?) ...[
          const SizedBox(height: DesignSpace.md),
          ActionButton(
            label: l10n.reschedulePickup,
            icon: const Icon(CupertinoIcons.calendar),
            onPressed: reschedule,
          ),
        ],
      ],
    );
  }
}
