import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White rounded card with a hairline border, optionally tappable.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
    this.borderWidth = 1,
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor, width: borderWidth),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Card with an ink border + check indicator when selected.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.enabled = true,
    this.borderColor,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  /// Border color when NOT selected (e.g. a permanent accent border).
  /// Selected always wins with the ink border.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: AppCard(
        padding: padding,
        borderColor: selected ? AppColors.ink : (borderColor ?? AppColors.line),
        borderWidth: selected ? 2 : 1,
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }
}

/// Filled check circle when selected, hollow ring otherwise.
class SelectionIndicator extends StatelessWidget {
  const SelectionIndicator({super.key, required this.selected, this.size = 30});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.ink : Colors.transparent,
        border: selected
            ? null
            : Border.all(color: AppColors.faint.withValues(alpha: .7), width: 2),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: Colors.white, size: size * .6)
          : null,
    );
  }
}
