import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand mark from the mockups: an ink rhombus with a teal drop.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * .62,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rhombus = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas
      ..drawPath(rhombus, Paint()..color = AppColors.ink)
      ..drawCircle(
        Offset(w / 2, h * .44),
        w * .16,
        Paint()..color = AppColors.teal,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
