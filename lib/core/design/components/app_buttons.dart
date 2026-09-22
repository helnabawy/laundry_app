import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';

/// How much weight the action carries.
enum ActionTone {
  /// The page's commit. Filled ink.
  primary,

  /// The driver's confirm. Filled hi-vis, so it is unmistakable in sun.
  field,

  /// A real alternative to the primary. Ruled, not filled.
  secondary,

  /// Destructive or a failure report.
  danger,
}

/// A press that is physically a press: the surface depresses and darkens
/// under the thumb, and disabled flattens into the ground rather than
/// merely fading.
class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ActionTone.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ActionTone tone;
  final bool loading;
  final Widget? icon;
  final bool expand;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  var _down = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, border) = switch (widget.tone) {
      ActionTone.primary => (colors.ink, colors.onInk, null),
      ActionTone.field => (colors.tag, colors.onTag, null),
      ActionTone.secondary => (
        const Color(0x00000000),
        colors.ink,
        colors.ruleStrong,
      ),
      ActionTone.danger => (
        const Color(0x00000000),
        colors.signal,
        colors.signal,
      ),
    };

    final bg = _enabled
        ? (_down
              ? Color.alphaBlend(colors.ink.withValues(alpha: .16), background)
              : background)
        : colors.tapeSunken;
    final fg = _enabled ? foreground : colors.inkDisabled;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? .985 : 1,
          duration: DesignMotion.quick,
          curve: DesignMotion.enter,
          child: AnimatedContainer(
            duration: DesignMotion.quick,
            width: widget.expand ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpace.xl,
              vertical: DesignSpace.md,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DesignRadius.control),
              border: border != null && _enabled
                  ? Border.all(color: border, width: DesignRule.medium)
                  : null,
            ),
            child: Center(
              child: widget.loading
                  ? SizedBox.square(
                      dimension: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon case final glyph?) ...[
                          IconTheme(
                            data: IconThemeData(color: fg, size: 20),
                            child: glyph,
                          ),
                          const SizedBox(width: DesignSpace.sm),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: DesignTypography.stamp(fg, size: 14),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An inline action. The only tinted text in the system — this is what tells
/// an iPhone user something is tappable.
class TintAction extends StatelessWidget {
  const TintAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final tint = enabled ? colors.tint : colors.inkDisabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: dense ? 36 : DesignSpace.touchTarget,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: tint, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing case final t?) ...[
                const SizedBox(width: DesignSpace.xs),
                IconTheme(
                  data: IconThemeData(color: tint, size: 16),
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

/// Pins the page's commit above the home indicator, on its own tape.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.children, this.note});

  final List<Widget> children;

  /// A last word before an irreversible action.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tape,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          DesignSpace.gutter,
          DesignSpace.md,
          DesignSpace.gutter,
          DesignSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note case final text?) ...[
              Text(
                text,
                textAlign: TextAlign.center,
                style: DesignTypography.fibreLine(colors.inkTertiary),
              ),
              const SizedBox(height: DesignSpace.md),
            ],
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: DesignSpace.sm),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
