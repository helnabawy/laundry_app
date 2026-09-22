import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/order_status.dart';
import '../utils/order_status_x.dart';

/// The order's state as a stamped impression rather than a coloured chip.
class OrderStatusStamp extends StatelessWidget {
  const OrderStatusStamp(this.status, {super.key, this.compact = false});

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) => StatusStamp(
    label: status.label(context.l10n),
    tone: status.stampTone,
    compact: compact,
  );
}
