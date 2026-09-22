import 'package:flutter/widgets.dart';

import '../glyphs/care_glyph.dart';
import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'stitch.dart';

/// One stage of the journey, as the strip draws it.
enum StageState { done, active, upcoming, failed }

class CustodyStage {
  const CustodyStage({
    required this.glyph,
    required this.label,
    required this.state,
  });

  final CareGlyph glyph;
  final String label;
  final StageState state;
}

/// The custody strip: the signature component.
///
/// Five glyphs at fixed positions. Only the active glyph is filled, and only
/// the active stage carries a word — completed stages carry a bar beneath,
/// upcoming stages stay outline. Labelling every stage overflows in Arabic and
/// at large Dynamic Type, so the active word is set once, below the band,
/// pointed at by a tick under its glyph.
class CustodyStrip extends StatelessWidget {
  const CustodyStrip({
    super.key,
    required this.stages,
    this.caption,
    this.captionSemantics,
  });

  /// A strip with nothing in custody: every glyph outline, no tick.
  const CustodyStrip.blank({super.key, required this.stages, this.caption})
    : captionSemantics = null;

  final List<CustodyStage> stages;

  /// The fibre-content line under the strip.
  final String? caption;
  final String? captionSemantics;

  int get _activeIndex => stages.indexWhere(
    (s) => s.state == StageState.active || s.state == StageState.failed,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = _activeIndex;
    final activeStage = active >= 0 ? stages[active] : null;

    return Semantics(
      container: true,
      label: activeStage == null
          ? caption
          : 'Stage ${active + 1} of ${stages.length}: ${activeStage.label}'
                '${caption == null ? '' : '. $caption'}',
      excludeSemantics: true,
      child: TapeBand(
        padding: const EdgeInsets.fromLTRB(
          DesignSpace.gutter,
          DesignSpace.lg,
          DesignSpace.gutter,
          DesignSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / stages.length;
                return SizedBox(
                  height: 34,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          for (final stage in stages)
                            Expanded(child: _Glyph(stage: stage)),
                        ],
                      ),
                      if (active >= 0)
                        PositionedDirectional(
                          start: slot * active + slot / 2 - 5,
                          bottom: 0,
                          child: _Tick(
                            color: activeStage!.state == StageState.failed
                                ? colors.signal
                                : colors.ink,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (activeStage != null) ...[
              const SizedBox(height: DesignSpace.sm),
              Text(
                activeStage.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: DesignTypography.stamp(
                  activeStage.state == StageState.failed
                      ? colors.signal
                      : colors.ink,
                  size: 13,
                ),
              ),
            ],
            if (caption case final line?) ...[
              const SizedBox(height: DesignSpace.xs),
              Text(
                line,
                textAlign: TextAlign.center,
                style: DesignTypography.fibreLine(colors.inkTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.stage});

  final CustodyStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (color, filled, bars, crossed) = switch (stage.state) {
      StageState.done => (colors.ink, false, 1, false),
      StageState.active => (colors.ink, true, 0, false),
      StageState.upcoming => (colors.inkTertiary, false, 0, false),
      StageState.failed => (colors.ink, false, 0, true),
    };
    return Center(
      child: AnimatedSwitcher(
        duration: DesignMotion.base,
        switchInCurve: DesignMotion.settle,
        child: CareGlyphIcon(
          key: ValueKey('${stage.glyph}-${stage.state}'),
          stage.glyph,
          color: color,
          size: 26,
          filled: filled,
          bars: bars,
          crossed: crossed,
          crossColor: colors.signal,
        ),
      ),
    );
  }
}

/// Points from the active glyph down to the word that names it.
class _Tick extends StatelessWidget {
  const _Tick({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(10, 5), painter: _TickPainter(color));
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}
