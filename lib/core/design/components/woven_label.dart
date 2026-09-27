import 'package:flutter/widgets.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';

/// Which cloth the woven label is cut from.
enum WovenTone {
  /// Ink ground, tape lettering — on tape and on the driver's tag.
  ink,

  /// Tape ground, ink lettering — sewn onto a photograph of cloth.
  tape,
}

/// The mark of the premium service.
///
/// A garment's ordinary care label is printed; a premium one is woven — a
/// solid ground with the lettering in the weave and its edge folded and
/// stitched down. This is that label: a solid block, never an outline, with a
/// stitched border inset from its edge. It is the only filled mark in the
/// system that isn't a state, so it never reads as one.
class WovenLabel extends StatelessWidget {
  const WovenLabel({
    super.key,
    required this.label,
    this.detail,
    this.tone = WovenTone.ink,
    this.compact = false,
    this.semanticLabel,
  });

  /// The service level, e.g. `VIP`.
  final String label;

  /// What the level promises, e.g. `24H`.
  final String? detail;

  final WovenTone tone;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (ground, thread) = switch (tone) {
      WovenTone.ink => (colors.ink, colors.onInk),
      // On a photograph the label is always light cloth, in either
      // appearance, as a real sewn-in label would be.
      WovenTone.tape => (const Color(0xFFFBFBF9), const Color(0xFF16181C)),
    };
    final size = compact ? 10.5 : 11.5;
    final style = DesignTypography.stamp(thread, size: size);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: CustomPaint(
        painter: _SelvedgePainter(ground: ground, thread: thread),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? DesignSpace.sm + 1 : DesignSpace.md,
            vertical: compact ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: style.copyWith(fontWeight: FontWeight.w800),
              ),
              if (detail case final d?) ...[
                // The weave's own divider: a woven bar, not a typed bullet.
                Container(
                  width: DesignRule.medium,
                  height: size,
                  margin: EdgeInsets.symmetric(
                    horizontal: compact ? 5 : DesignSpace.sm - 1,
                  ),
                  color: thread.withValues(alpha: .55),
                ),
                Text(d.toUpperCase(), style: style),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid ground, and a dashed stitch running 2pt inside the edge.
class _SelvedgePainter extends CustomPainter {
  const _SelvedgePainter({required this.ground, required this.thread});

  final Color ground;
  final Color thread;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(DesignRadius.slot),
    );
    canvas.drawRRect(outer, Paint()..color = ground);

    final inset = Offset.zero & size;
    final stitch = inset.deflate(2.5);
    final paint = Paint()
      ..color = thread.withValues(alpha: .5)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.butt;
    const dash = 2.4;
    const gap = 1.8;

    void run(Offset from, Offset to) {
      final length = (to - from).distance;
      final dir = (to - from) / length;
      for (var d = 0.0; d < length; d += dash + gap) {
        final end = d + dash > length ? length : d + dash;
        canvas.drawLine(from + dir * d, from + dir * end, paint);
      }
    }

    run(stitch.topLeft, stitch.topRight);
    run(stitch.topRight, stitch.bottomRight);
    run(stitch.bottomRight, stitch.bottomLeft);
    run(stitch.bottomLeft, stitch.topLeft);
  }

  @override
  bool shouldRepaint(_SelvedgePainter old) =>
      old.ground != ground || old.thread != thread;
}

/// Twin-needle stitching: two parallel runs of thread, the finish a premium
/// garment gets at its hems. Frames the premium service where a single
/// [StitchRule] would frame the standard one.
class TwinStitch extends StatelessWidget {
  const TwinStitch({super.key, this.color, this.indent = 0});

  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final thread = color ?? context.colors.ink;
    Widget line() => SizedBox(
      height: DesignRule.hair,
      width: double.infinity,
      child: ColoredBox(color: thread),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [line(), const SizedBox(height: 2), line()],
      ),
    );
  }
}
