import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/design_metrics.dart';

/// The pictogram family.
///
/// These are drawn in the grammar of a garment care label — one stroke weight,
/// one optical size, closed geometric containers — but they are *our* symbols
/// for concepts this product owns. The standardised GINETEX symbols
/// ([CareSymbol]) are used in exactly one place: invoice item rows, where the
/// facility can truthfully report the treatment it applied.
enum CareGlyph {
  /// Items going into our hands.
  collect,

  /// Items held.
  custody,

  /// Items counted and priced.
  inspect,

  /// Items being cleaned.
  treat,

  /// Items coming back.
  deliver,

  clothes,
  textiles,
  carpets,
  curtains,
}

/// The standardised care symbols. Truthful reporting only — never decoration.
enum CareSymbol { wash, bleach, dry, iron, professional }

/// A glyph with its modifiers.
///
/// Meaning changes by modifier, never by adding a new symbol: a dot inside is
/// service level, a bar beneath is a stage completed, a cross through is a
/// refusal or a failure.
class CareGlyphIcon extends StatelessWidget {
  const CareGlyphIcon(
    this.glyph, {
    super.key,
    required this.color,
    this.size = 24,
    this.filled = false,
    this.dots = 0,
    this.bars = 0,
    this.crossed = false,
    this.crossColor,
    this.semanticLabel,
  }) : assert(dots >= 0 && dots <= 3),
       assert(bars >= 0 && bars <= 2);

  final CareGlyph glyph;
  final Color color;
  final double size;

  /// The active stage fills; everything else is outline.
  final bool filled;

  /// Service level. One dot standard, two VIP.
  final int dots;

  /// Stages completed.
  final int bars;

  /// Refused, failed, or unavailable.
  final bool crossed;
  final Color? crossColor;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      size: Size.square(size),
      painter: _CareGlyphPainter(
        glyph: glyph,
        color: color,
        filled: filled,
        dots: dots,
        bars: bars,
        crossed: crossed,
        crossColor: crossColor ?? color,
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: semanticLabel == null
          ? ExcludeSemantics(child: painted)
          : Semantics(label: semanticLabel, image: true, child: painted),
    );
  }
}

class _CareGlyphPainter extends CustomPainter {
  _CareGlyphPainter({
    required this.glyph,
    required this.color,
    required this.filled,
    required this.dots,
    required this.bars,
    required this.crossed,
    required this.crossColor,
  });

  final CareGlyph glyph;
  final Color color;
  final bool filled;
  final int dots;
  final int bars;
  final bool crossed;
  final Color crossColor;

  /// Every glyph is authored on a 24pt grid and scaled from there, so the
  /// stroke stays optically identical at any size.
  static const _grid = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas
      ..save()
      ..scale(scale);

    // Bars live below the body, so the body is compressed to make room.
    final bodyHeight = bars > 0 ? 19.0 : 24.0;
    final (body, detail, dotAnchor) = _geometry(glyph, bodyHeight);

    Paint stroke() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = DesignRule.glyphStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    if (filled) {
      // A filled glyph is a solid silhouette with its own detail knocked back
      // out of the ink — otherwise every container collapses to a blank block
      // and the family stops being readable at its most important state.
      canvas.saveLayer(Rect.fromLTWH(0, 0, _grid, _grid), Paint());
      canvas
        ..drawPath(body, Paint()..color = color)
        ..drawPath(body, stroke());
      final clear = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = DesignRule.glyphStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.clear;
      canvas.drawPath(detail, clear);
      if (dots > 0) _paintDots(canvas, dotAnchor, true);
      canvas.restore();
    } else {
      canvas
        ..drawPath(body, stroke())
        ..drawPath(detail, stroke());
      if (dots > 0) _paintDots(canvas, dotAnchor, false);
    }

    if (bars > 0) _paintBars(canvas, bodyHeight);
    if (crossed) _paintCross(canvas, bodyHeight);

    canvas.restore();
  }

  void _paintDots(Canvas canvas, Rect anchor, bool inverted) {
    const radius = 1.45;
    final spacing = anchor.width / (dots + 1);
    final paint = Paint()
      ..color = inverted ? const Color(0xFF000000) : color
      ..blendMode = inverted ? BlendMode.clear : BlendMode.srcOver;
    // Inside a filled glyph the dots are cleared out of the ink.
    for (var i = 1; i <= dots; i++) {
      canvas.drawCircle(
        Offset(anchor.left + spacing * i, anchor.center.dy),
        radius,
        paint,
      );
    }
  }

  void _paintBars(Canvas canvas, double bodyHeight) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = DesignRule.glyphStroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (var i = 0; i < bars; i++) {
      final y = bodyHeight + 1.8 + i * 3.2;
      canvas.drawLine(Offset(5, y), Offset(19, y), paint);
    }
  }

  void _paintCross(Canvas canvas, double bodyHeight) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = DesignRule.glyphStroke + .3
      ..strokeCap = StrokeCap.round
      ..color = crossColor;
    final inset = bodyHeight * .12;
    canvas
      ..drawLine(
        Offset(inset, inset),
        Offset(24 - inset, bodyHeight - inset),
        paint,
      )
      ..drawLine(
        Offset(24 - inset, inset),
        Offset(inset, bodyHeight - inset),
        paint,
      );
  }

  /// The fillable silhouette, the detail drawn inside it, and the rect dots
  /// are distributed across.
  (Path, Path, Rect) _geometry(CareGlyph glyph, double h) {
    final body = Path();
    final detail = Path();
    // Scale the authored 24pt drawing down when bars steal vertical room.
    final k = h / 24.0;
    double y(double v) => v * k;
    double r(double v) => v * (k < .8 ? .8 : (k > 1 ? 1 : k));

    switch (glyph) {
      case CareGlyph.collect:
      case CareGlyph.deliver:
        // A basket, open at the top, with the item entering or leaving.
        body
          ..moveTo(3.5, y(9))
          ..lineTo(5.6, y(20.5))
          ..lineTo(18.4, y(20.5))
          ..lineTo(20.5, y(9))
          ..close();
        final isOut = glyph == CareGlyph.deliver;
        final tipY = isOut ? y(2.5) : y(8.5);
        final tailY = isOut ? y(8.5) : y(2.5);
        detail
          ..moveTo(12, tailY)
          ..lineTo(12, tipY)
          ..moveTo(9.2, isOut ? y(5.3) : y(5.7))
          ..lineTo(12, tipY)
          ..lineTo(14.8, isOut ? y(5.3) : y(5.7));
        return (body, detail, Rect.fromLTRB(6.5, y(11), 17.5, y(18)));

      case CareGlyph.custody:
        // A closed container: what we are holding.
        body.addRRect(
          RRect.fromLTRBR(3.5, y(5.5), 20.5, y(20.5), const Radius.circular(2)),
        );
        detail
          ..moveTo(3.5, y(10))
          ..lineTo(20.5, y(10));
        return (body, detail, Rect.fromLTRB(6, y(12), 18, y(18)));

      case CareGlyph.inspect:
        // A lens over the goods.
        body.addOval(
          Rect.fromCircle(center: Offset(12, y(12)), radius: r(8.5)),
        );
        detail.addOval(
          Rect.fromCircle(center: Offset(12, y(12)), radius: r(3.2)),
        );
        return (body, detail, Rect.fromLTRB(7, y(12), 17, y(12)));

      case CareGlyph.treat:
        // The tub: the one journey glyph that borrows the care-label form,
        // because treatment is exactly what it means.
        body
          ..moveTo(2.5, y(8.5))
          ..lineTo(4.8, y(20.5))
          ..lineTo(19.2, y(20.5))
          ..lineTo(21.5, y(8.5))
          ..close();
        detail
          ..moveTo(3.2, y(12))
          ..cubicTo(6, y(9.6), 9, y(14.4), 12, y(12))
          ..cubicTo(15, y(9.6), 18, y(14.4), 20.8, y(12));
        return (body, detail, Rect.fromLTRB(6.5, y(16), 17.5, y(16)));

      case CareGlyph.clothes:
        // A shirt, read by its shoulder line and collar.
        body
          ..moveTo(4, y(8.5))
          ..lineTo(9, y(4))
          ..lineTo(12, y(6.6))
          ..lineTo(15, y(4))
          ..lineTo(20, y(8.5))
          ..lineTo(16.8, y(11.4))
          ..lineTo(16.8, y(20.5))
          ..lineTo(7.2, y(20.5))
          ..lineTo(7.2, y(11.4))
          ..close();
        return (body, detail, Rect.fromLTRB(8.5, y(15.5), 15.5, y(15.5)));

      case CareGlyph.textiles:
        // Folded layers, stacked.
        for (var i = 0; i < 3; i++) {
          final top = y(6.0 + i * 4.8);
          body.addRRect(
            RRect.fromLTRBR(
              3.5 + i * .9,
              top,
              20.5 - i * .9,
              top + y(3.2),
              const Radius.circular(1.4),
            ),
          );
        }
        return (body, detail, Rect.fromLTRB(7, y(19), 17, y(19)));

      case CareGlyph.carpets:
        // A rolled edge against a flat field.
        body
          ..moveTo(8, y(5))
          ..lineTo(20.5, y(5))
          ..lineTo(20.5, y(19))
          ..lineTo(8, y(19))
          ..close();
        body.addOval(Rect.fromCircle(center: Offset(8, y(12)), radius: r(7)));
        detail.addOval(
          Rect.fromCircle(center: Offset(8, y(12)), radius: r(2.6)),
        );
        return (body, detail, Rect.fromLTRB(12, y(12), 19, y(12)));

      case CareGlyph.curtains:
        // A hung field with pleats and a weighted hem.
        body
          ..moveTo(3.5, y(17))
          ..cubicTo(7, y(21), 10.5, y(14), 14, y(18))
          ..cubicTo(16.5, y(20.8), 18.5, y(17.5), 20.5, y(19))
          ..lineTo(20.5, y(4.5))
          ..lineTo(3.5, y(4.5))
          ..close();
        for (var i = 0; i < 3; i++) {
          final x = 6.5 + i * 5.5;
          detail
            ..moveTo(x, y(6))
            ..lineTo(x, y(16));
        }
        return (body, detail, Rect.fromLTRB(7, y(11), 17, y(11)));
    }
  }

  @override
  bool shouldRepaint(_CareGlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.filled != filled ||
      old.dots != dots ||
      old.bars != bars ||
      old.crossed != crossed ||
      old.crossColor != crossColor;
}

/// The standardised care symbols, drawn in the same stroke as [CareGlyphIcon].
///
/// Only ever rendered beside an item the facility actually treated.
class CareSymbolIcon extends StatelessWidget {
  const CareSymbolIcon(
    this.symbol, {
    super.key,
    required this.color,
    this.size = 20,
    this.semanticLabel,
  });

  final CareSymbol symbol;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      size: Size.square(size),
      painter: _CareSymbolPainter(symbol: symbol, color: color),
    );
    return SizedBox.square(
      dimension: size,
      child: semanticLabel == null
          ? ExcludeSemantics(child: painted)
          : Semantics(label: semanticLabel, image: true, child: painted),
    );
  }
}

class _CareSymbolPainter extends CustomPainter {
  _CareSymbolPainter({required this.symbol, required this.color});

  final CareSymbol symbol;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas
      ..save()
      ..scale(scale);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = DesignRule.glyphStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path = Path();
    switch (symbol) {
      case CareSymbol.wash:
        path
          ..moveTo(2.5, 7.5)
          ..lineTo(4.8, 20)
          ..lineTo(19.2, 20)
          ..lineTo(21.5, 7.5)
          ..close()
          ..moveTo(3.1, 11)
          ..cubicTo(6, 8.6, 9, 13.4, 12, 11)
          ..cubicTo(15, 8.6, 18, 13.4, 20.9, 11);
      case CareSymbol.bleach:
        path
          ..moveTo(12, 3.5)
          ..lineTo(21, 20.5)
          ..lineTo(3, 20.5)
          ..close();
      case CareSymbol.dry:
        path
          ..addRect(const Rect.fromLTRB(3.5, 4.5, 20.5, 19.5))
          ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 4.8));
      case CareSymbol.iron:
        path
          ..moveTo(3, 18)
          ..lineTo(21, 18)
          ..lineTo(18.4, 9.5)
          ..cubicTo(17.4, 6.6, 15, 6, 12, 6)
          ..cubicTo(8, 6, 5.6, 7.4, 4.4, 10.4)
          ..close();
      case CareSymbol.professional:
        path.addOval(
          Rect.fromCircle(center: const Offset(12, 12), radius: 8.6),
        );
        // The P that marks professional care.
        path
          ..moveTo(9.6, 16.4)
          ..lineTo(9.6, 7.6)
          ..lineTo(13, 7.6)
          ..arcTo(
            Rect.fromLTRB(9.6, 7.6, 15.8, 12.6),
            -math.pi / 2,
            math.pi,
            false,
          )
          ..lineTo(9.6, 12.6);
    }

    canvas
      ..drawPath(path, stroke)
      ..restore();
  }

  @override
  bool shouldRepaint(_CareSymbolPainter old) =>
      old.symbol != symbol || old.color != color;
}

/// A glyph whose modifiers change in place.
///
/// This is the system's one authored moment: choosing a service level adds a
/// dot inside the glyph and slides a bar beneath it, which teaches the whole
/// grammar in a single gesture. Honours Reduce Motion by cross-fading.
class AnimatedCareGlyphIcon extends StatelessWidget {
  const AnimatedCareGlyphIcon(
    this.glyph, {
    super.key,
    required this.color,
    this.size = 24,
    this.filled = false,
    this.dots = 0,
    this.bars = 0,
    this.crossed = false,
    this.crossColor,
    this.semanticLabel,
  });

  final CareGlyph glyph;
  final Color color;
  final double size;
  final bool filled;
  final int dots;
  final int bars;
  final bool crossed;
  final Color? crossColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => reduceMotion
          ? FadeTransition(opacity: animation, child: child)
          : FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: .86, end: 1).animate(animation),
                child: child,
              ),
            ),
      child: CareGlyphIcon(
        key: ValueKey('$glyph-$dots-$bars-$crossed-$filled'),
        glyph,
        color: color,
        size: size,
        filled: filled,
        dots: dots,
        bars: bars,
        crossed: crossed,
        crossColor: crossColor,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
