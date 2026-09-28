import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// The cart's quantity control: a lone `+` when nothing is in the cart yet,
/// a `− N +` row in a sunken well once it is — the same reserved-numeric-slot
/// vocabulary as [ReservedSlot] elsewhere in the system.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (quantity <= 0) {
      return _StepButton(
        icon: CupertinoIcons.add,
        onTap: onIncrement,
        filled: true,
        semanticLabel: l10n.addToCart,
      );
    }
    final colors = context.colors;
    return ReservedSlot(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpace.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: CupertinoIcons.minus, onTap: onDecrement),
          SizedBox(
            width: 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: DesignTypography.numeric(colors.ink, size: 15),
            ),
          ),
          _StepButton(icon: CupertinoIcons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? colors.ink : const Color(0x00000000),
            borderRadius: BorderRadius.circular(DesignRadius.slot),
            border: filled
                ? null
                : Border.all(color: colors.ruleStrong, width: DesignRule.hair),
          ),
          child: Icon(icon, size: 16, color: filled ? colors.onInk : colors.ink),
        ),
      ),
    );
  }
}
