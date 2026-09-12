import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/labeled_rows.dart';
import '../../domain/entities/order_status.dart';
import '../utils/order_status_x.dart';

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = status.tone;
    return Pill(
      label: status.label(context.l10n),
      foreground: tone.foreground,
      background: tone.background,
    );
  }
}
