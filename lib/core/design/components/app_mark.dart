import 'package:flutter/widgets.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';

/// The brand mark: a label tab hanging from its stitch.
///
/// Drawn, not lettered, so it reads the same at 22pt in a nav bar and at
/// 96pt on the splash. The notch is the tail of a sewn-in label.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 88, this.color, this.semanticLabel});

  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.colors.ink;
    final mark = CustomPaint(
      size: Size(size * .84, size),
      painter: _MarkPainter(ink),
    );
    return SizedBox(
      width: size * .84,
      height: size,
      child: semanticLabel == null
          ? ExcludeSemantics(child: mark)
          : Semantics(label: semanticLabel, image: true, child: mark),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Authored on a 84 x 100 grid.
    final sx = size.width / 84;
    final sy = size.height / 100;
    canvas
      ..save()
      ..scale(sx, sy);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // The stitch the label hangs from.
    var x = 2.0;
    while (x < 82) {
      canvas.drawLine(Offset(x, 10), Offset(x + 6, 10), stroke);
      x += 12;
    }

    // The tab, notched at the tail.
    final tab = Path()
      ..moveTo(13, 26)
      ..lineTo(71, 26)
      ..lineTo(71, 92)
      ..lineTo(42, 74)
      ..lineTo(13, 92)
      ..close();
    canvas.drawPath(tab, stroke);

    // The two printed lines every label carries.
    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas
      ..drawLine(const Offset(27, 45), const Offset(57, 45), rule)
      ..drawLine(const Offset(27, 58), const Offset(46, 58), rule)
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

/// The mark with the product's name beneath it.
class AppMarkLockup extends StatelessWidget {
  const AppMarkLockup({
    super.key,
    required this.name,
    this.tagline,
    this.size = 84,
  });

  final String name;
  final String? tagline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppMark(size: size, semanticLabel: name),
        const SizedBox(height: DesignSpace.xl),
        Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          style: DesignTypography.serial(colors.ink, size: size * .30),
        ),
        if (tagline case final line?) ...[
          const SizedBox(height: DesignSpace.sm),
          Text(
            line,
            textAlign: TextAlign.center,
            style: DesignTypography.fibreLine(colors.inkSecondary, size: 12),
          ),
        ],
      ],
    );
  }
}
