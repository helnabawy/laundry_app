import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';

/// A hairline rule — the stitch that divides one field of the label from the
/// next. This is the system's only divider; there are no card borders.
class StitchRule extends StatelessWidget {
  const StitchRule({
    super.key,
    this.color,
    this.dashed = false,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = DesignRule.hair,
  });

  /// The perforation: used where something detaches or is reserved.
  const StitchRule.dashed({
    super.key,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = DesignRule.hair,
  }) : dashed = true;

  final Color? color;
  final bool dashed;
  final double indent;
  final double endIndent;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final line = color ?? context.colors.rule;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: thickness,
        width: double.infinity,
        child: dashed
            ? CustomPaint(painter: _DashPainter(line, thickness))
            : ColoredBox(color: line),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color, this.thickness);

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 2.6;
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.thickness != thickness;
}

/// A band of label tape: stitched along both long edges, running the full
/// width of the screen. The system's primary surface.
class TapeBand extends StatelessWidget {
  const TapeBand({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignSpace.gutter,
      vertical: DesignSpace.lg,
    ),
    this.topStitch = true,
    this.bottomStitch = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final bool topStitch;
  final bool bottomStitch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? colors.tapeRecessed),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (topStitch) const StitchRule(),
          Padding(padding: padding, child: child),
          if (bottomStitch) const StitchRule(),
        ],
      ),
    );
  }
}

/// A well: the recessed field a reserved value sits in.
class ReservedSlot extends StatelessWidget {
  const ReservedSlot({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignSpace.md,
      vertical: DesignSpace.sm,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tapeSunken,
        borderRadius: BorderRadius.circular(DesignRadius.slot),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
