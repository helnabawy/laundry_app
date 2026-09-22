import 'package:flutter/material.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'stitch.dart';

/// The order serial, set as matter.
///
/// Scale carries identity here so colour does not have to. The digits sit in
/// reserved tabular slots and change in place.
class SerialBlock extends StatelessWidget {
  const SerialBlock({
    super.key,
    required this.serial,
    this.caption,
    this.size = 40,
    this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  final String serial;

  /// The fibre-content line under the number.
  final String? caption;
  final double size;
  final Color? color;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = color ?? colors.ink;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          serial,
          style: DesignTypography.serial(ink, size: size),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption case final line?) ...[
          const SizedBox(height: DesignSpace.xs),
          Text(
            line,
            style: DesignTypography.fibreLine(
              ink == colors.ink
                  ? colors.inkTertiary
                  : ink.withValues(alpha: .8),
            ),
          ),
        ],
      ],
    );
  }
}

/// The amount block — the product's positioning, made structural.
///
/// Before inspection the slot is drawn, ruled and visibly held open with an
/// em-dash placeholder. It is never a struck-through figure: a strikethrough
/// reads as a cancelled or discounted price, which is the opposite of the
/// truth here.
class AmountSlot extends StatelessWidget {
  const AmountSlot({
    super.key,
    required this.label,
    required this.placeholder,
    this.amount,
    this.pendingNote,
    this.emphasised = true,
  });

  final String label;

  /// What the reserved field reads before inspection, already carrying the
  /// currency mark in the locale's own order (e.g. `AED —.——`). Priced and
  /// pending share one width because they share one pattern.
  final String placeholder;

  /// Null until the facility has inspected and priced the items.
  final String? amount;

  /// What the customer should understand while the slot is empty.
  final String? pendingNote;

  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final pending = amount == null;

    return Semantics(
      container: true,
      label: pending
          ? '$label. ${pendingNote ?? 'Not set yet'}'
          : '$label $amount',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tape,
          border: Border.all(color: colors.rule),
          borderRadius: BorderRadius.circular(DesignRadius.panel),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: DesignTypography.stamp(colors.inkSecondary),
              ),
              const SizedBox(height: DesignSpace.md),
              // The figure changes inside the slot it was always reserved in:
              // same plate, same size, same width. It never reflows into a
              // different container when the price lands.
              ReservedSlot(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSpace.md,
                  vertical: DesignSpace.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: DesignMotion.base,
                        switchInCurve: DesignMotion.settle,
                        child: Text(
                          pending ? placeholder : amount!,
                          key: ValueKey(pending),
                          style: DesignTypography.numeric(
                            pending ? colors.inkTertiary : colors.ink,
                            size: emphasised ? 26 : 20,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (pending && pendingNote != null) ...[
                const SizedBox(height: DesignSpace.md),
                const StitchRule.dashed(),
                const SizedBox(height: DesignSpace.md),
                Text(
                  pendingNote!,
                  style: text.bodySmall?.copyWith(color: colors.inkSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A stamped state mark. Replaces the status chip: impression, not pill.
class StatusStamp extends StatelessWidget {
  const StatusStamp({
    super.key,
    required this.label,
    this.tone = StampTone.neutral,
    this.compact = false,
  });

  final String label;
  final StampTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = switch (tone) {
      StampTone.neutral => colors.ink,
      StampTone.quiet => colors.inkSecondary,
      StampTone.alert => colors.signal,
      StampTone.field => colors.onTag,
    };
    final ground = tone == StampTone.field ? colors.tag : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DesignSpace.sm : DesignSpace.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: ground,
        border: ground == null
            ? Border.all(
                color: ink.withValues(alpha: .45),
                width: DesignRule.hair,
              )
            : null,
        borderRadius: BorderRadius.circular(DesignRadius.slot),
      ),
      child: Text(
        label.toUpperCase(),
        style: DesignTypography.stamp(ink, size: compact ? 10.5 : 11.5),
      ),
    );
  }
}

enum StampTone { neutral, quiet, alert, field }
