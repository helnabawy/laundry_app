import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/service_tier.dart';

/// The woven label for a VIP order: the level and the turnaround it
/// promises, e.g. `VIP | 24H`. Callers show it only when [tier] is VIP.
class VipMark extends StatelessWidget {
  const VipMark({
    super.key,
    required this.tier,
    this.tone = WovenTone.ink,
    this.compact = true,
  });

  final ServiceTier tier;
  final WovenTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WovenLabel(
      label: tier.name,
      detail: l10n.hoursShort(tier.deliveryHours),
      tone: tone,
      compact: compact,
      semanticLabel: l10n.vipSemantics(tier.name, tier.deliveryHours),
    );
  }
}
