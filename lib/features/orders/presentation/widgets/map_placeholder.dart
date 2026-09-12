import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../addresses/domain/entities/address.dart';
import '../utils/launchers.dart';

/// A simplified static map (no Maps SDK/API key in this MVP) with an
/// "Open in Maps" action that hands off to the device's real maps app.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            color: const Color(0xFFDCE7E7),
            child: CustomPaint(painter: _GridPainter()),
          ),
          const Center(
            child: Icon(Icons.location_on, color: AppColors.danger, size: 40),
          ),
          PositionedDirectional(
            bottom: 12,
            start: 12,
            child: FilledButton.tonalIcon(
              onPressed: () => launchMaps(address),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(l10n.openInMaps),
              style: FilledButton.styleFrom(backgroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
