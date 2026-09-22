import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'stitch.dart';

class TapeTab {
  const TapeTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// The tab bar, at iOS metrics: 49pt of bar above the home indicator, the
/// selected destination in ink, the rest quiet. Sections only — never actions.
class TapeTabBar extends StatelessWidget {
  const TapeTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    this.ground,
  });

  final List<TapeTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: ground ?? colors.tape),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StitchRule(),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 49,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _Tab(
                        tab: tabs[i],
                        selected: i == currentIndex,
                        index: i,
                        total: tabs.length,
                        onTap: () {
                          if (i != currentIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.index,
    required this.total,
    required this.onTap,
  });

  final TapeTab tab;
  final bool selected;
  final int index;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = selected ? colors.ink : colors.inkTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      hint: 'Tab ${index + 1} of $total',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, color: ink, size: 25),
            const SizedBox(height: DesignSpace.xxs),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTypography.stamp(ink, size: 10),
            ),
          ],
        ),
      ),
    );
  }
}
