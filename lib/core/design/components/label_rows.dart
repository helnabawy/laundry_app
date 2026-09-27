import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'stitch.dart';

/// One label anatomy, never varied: a glyph at a fixed left position, the
/// title, a supporting line, and a value at the end. Every list in the app —
/// services, orders, stops, invoice items, settings — is this row.
class LabelRow extends StatefulWidget {
  const LabelRow({
    super.key,
    this.leading,
    required this.title,
    this.badge,
    this.subtitle,
    this.trailing,
    this.value,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignSpace.gutter,
      vertical: DesignSpace.md,
    ),
  });

  final Widget? leading;
  final String title;

  /// A mark set on the title's line, after it — the woven service label.
  final Widget? badge;

  final String? subtitle;

  /// Sits at the end of the row, after [value].
  final Widget? trailing;

  /// A tabular value in its reserved slot.
  final String? value;

  final VoidCallback? onTap;

  /// Selection inverts the row. It is never a tinted fill.
  final bool selected;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  @override
  State<LabelRow> createState() => _LabelRowState();
}

class _LabelRowState extends State<LabelRow> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final tappable = widget.onTap != null && widget.enabled;

    final ground = switch ((widget.selected, _down)) {
      (true, _) => colors.ink,
      (false, true) => colors.tapeRecessed,
      _ => const Color(0x00000000),
    };
    final ink = widget.selected
        ? colors.onInk
        : (widget.enabled ? colors.ink : colors.inkDisabled);
    final support = widget.selected
        ? colors.onInk.withValues(alpha: .72)
        : (widget.enabled ? colors.inkSecondary : colors.inkDisabled);

    return Semantics(
      button: tappable,
      selected: widget.selected,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: tappable ? (_) => setState(() => _down = true) : null,
        onTapUp: tappable ? (_) => setState(() => _down = false) : null,
        onTapCancel: tappable ? () => setState(() => _down = false) : null,
        onTap: tappable
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: DesignMotion.quick,
          color: ground,
          constraints: const BoxConstraints(minHeight: DesignSpace.touchTarget),
          padding: widget.padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.leading case final glyph?) ...[
                // Glyphs align on a 30pt column; a photographic thumb is
                // wider and takes the room it needs rather than being squeezed.
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 30),
                  child: Center(widthFactor: 1, child: glyph),
                ),
                const SizedBox(width: DesignSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: text.bodyLarge?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.badge case final mark?) ...[
                          const SizedBox(width: DesignSpace.sm),
                          mark,
                        ],
                      ],
                    ),
                    if (widget.subtitle case final sub?) ...[
                      const SizedBox(height: DesignSpace.xxs),
                      Text(
                        sub,
                        style: text.bodySmall?.copyWith(color: support),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.value case final v?) ...[
                const SizedBox(width: DesignSpace.md),
                Text(v, style: DesignTypography.numeric(ink)),
              ],
              if (widget.trailing case final t?) ...[
                const SizedBox(width: DesignSpace.sm),
                IconTheme(
                  data: IconThemeData(color: support, size: 18),
                  child: t,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A run of [LabelRow]s stitched together, on its own ground.
class LabelGroup extends StatelessWidget {
  const LabelGroup({
    super.key,
    required this.children,
    this.heading,
    this.trailing,
    this.stitched = true,
  });

  final List<Widget> children;
  final String? heading;
  final Widget? trailing;
  final bool stitched;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading case final title?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.aboveHeading,
              DesignSpace.gutter,
              DesignSpace.belowHeading,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: DesignTypography.stamp(colors.inkSecondary),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(color: colors.tape),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StitchRule(),
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0 && stitched)
                  const StitchRule(indent: DesignSpace.gutter),
                children[i],
              ],
              const StitchRule(),
            ],
          ),
        ),
      ],
    );
  }
}

/// A "label ....... value" line inside a summary block.
class FieldLine extends StatelessWidget {
  const FieldLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasised = false,
    this.tone,
  });

  final String label;
  final String value;
  final bool emphasised;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: colors.inkSecondary),
            ),
          ),
          const SizedBox(width: DesignSpace.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: DesignTypography.numeric(
                tone ?? colors.ink,
                size: emphasised ? 19 : 16,
                weight: emphasised ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stamped section heading, used where a [LabelGroup] is not the container.
class StampHeading extends StatelessWidget {
  const StampHeading(this.title, {super.key, this.trailing, this.padding});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding:
          padding ??
          const EdgeInsets.only(
            top: DesignSpace.aboveHeading,
            bottom: DesignSpace.belowHeading,
          ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: DesignTypography.stamp(colors.inkSecondary),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
