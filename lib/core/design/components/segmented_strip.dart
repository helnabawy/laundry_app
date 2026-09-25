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
