import 'package:flutter/widgets.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';

/// A few fields on one strip; the chosen one inverts.
class SegmentedStrip extends StatelessWidget {
  const SegmentedStrip({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.ruleStrong),
        borderRadius: BorderRadius.circular(DesignRadius.slot),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: DesignMotion.quick,
                    height: 40,
                    alignment: Alignment.center,
                    color: i == index ? colors.ink : const Color(0x00000000),
                    child: Text(
                      labels[i].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTypography.stamp(
                        i == index ? colors.onInk : colors.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A horizontally-scrolling row of pill filter chips — "All" plus each
/// category — the ink fills the selected one. Unlike [SegmentedStrip], the
/// set is open-ended and only one chip is ever selected at a time, so it
/// reads as a filter rather than a fixed set of fields.
class ChipStrip extends StatelessWidget {
  const ChipStrip({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;

  /// Null selects nothing (every chip reads as unselected).
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignSpace.sm),
        itemBuilder: (context, i) => _Chip(
          label: labels[i],
          selected: i == selectedIndex,
          onTap: () => onSelected(i),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesignMotion.quick,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.lg),
          decoration: BoxDecoration(
            color: selected ? colors.ink : const Color(0x00000000),
            border: Border.all(
              color: selected ? colors.ink : colors.rule,
              width: DesignRule.hair,
            ),
            borderRadius: BorderRadius.circular(DesignRadius.control),
          ),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DesignTypography.stamp(
              selected ? colors.onInk : colors.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
