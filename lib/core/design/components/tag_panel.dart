import 'package:flutter/material.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'stitch.dart';

/// The routing tag: the driver's side of the same label.
///
/// Hi-vis ground, ink type, marking-ink violet still carrying the actions —
/// one system, the other copy. Colour is committed here because the driver
/// reads this in direct sun, at arm's length, in a moving vehicle.
class TagPanel extends StatelessWidget {
  const TagPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      DesignSpace.gutter,
      DesignSpace.lg,
      DesignSpace.gutter,
      DesignSpace.lg,
    ),
    this.ruledTop = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Divides this band from the one above it with an ink rule. One hi-vis
  /// tone carries the whole surface; separation is a rule, never a second
  /// yellow.
  final bool ruledTop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tag,
        border: ruledTop
            ? Border(
                top: BorderSide(color: colors.onTag, width: DesignRule.heavy),
              )
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The driver's day, stamped across the top of the tag.
class TagHeader extends StatelessWidget {
  const TagHeader({
    super.key,
    required this.title,
    required this.shift,
    this.count,
    this.countLabel,
    this.trailing,
  });

  final String title;
  final String shift;

  /// Numerals live in a reserved slot and change in place.
  final String? count;
  final String? countLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TagPanel(
      padding: const EdgeInsets.fromLTRB(
        DesignSpace.gutter,
        DesignSpace.md,
        DesignSpace.gutter,
        DesignSpace.xl,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: colors.onTag),
                      ),
                      const SizedBox(height: DesignSpace.xxs),
                      Text(
                        shift.toUpperCase(),
                        style: DesignTypography.stamp(
                          colors.onTag.withValues(alpha: .72),
                        ),
                      ),
                    ],
                  ),
                ),
                if (count case final value?) ...[
                  const SizedBox(width: DesignSpace.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: DesignTypography.serial(colors.onTag, size: 34),
                      ),
                      if (countLabel case final label?)
                        Text(
                          label.toUpperCase(),
                          style: DesignTypography.stamp(
                            colors.onTag.withValues(alpha: .72),
                            size: 10.5,
                          ),
                        ),
                    ],
                  ),
                ],
                ?trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A stop, as a tag row. The same label anatomy as everywhere else, printed
/// on the tag instead of the tape.
class TagRow extends StatelessWidget {
  const TagRow({
    super.key,
    required this.serial,
    required this.title,
    required this.subtitle,
    this.window,
    this.leading,
    this.onTap,
    this.stamp,
  });

  final String serial;
  final String title;
  final String subtitle;
  final String? window;
  final Widget? leading;
  final VoidCallback? onTap;
  final Widget? stamp;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: colors.tape,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSpace.gutter,
                  DesignSpace.md,
                  DesignSpace.gutter,
                  DesignSpace.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading case final glyph?) ...[
                      SizedBox(width: 30, child: Center(child: glyph)),
                      const SizedBox(width: DesignSpace.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                serial,
                                style: DesignTypography.numeric(
                                  colors.ink,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              if (window case final w?) ...[
                                const SizedBox(width: DesignSpace.sm),
                                Text(
                                  w,
                                  style: DesignTypography.fibreLine(
                                    colors.inkTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: DesignSpace.xs),
                          Text(
                            title,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: DesignSpace.xxs),
                          Text(
                            subtitle,
                            style: text.bodySmall?.copyWith(
                              color: colors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stamp case final s?) ...[
                      const SizedBox(width: DesignSpace.sm),
                      s,
                    ],
                  ],
                ),
              ),
              const StitchRule(),
            ],
          ),
        ),
      ),
    );
  }
}
