import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// Where the map opens with no pin and no GPS fix.
const defaultMapCenter = LatLng(
  AppConfig.mapDefaultLatitude,
  AppConfig.mapDefaultLongitude,
);

/// Street-level: close enough to tell one villa from its neighbour.
const pinZoom = 17.0;

/// `24.45390, 54.37730` — always Latin digits, always LTR, so the same pair
/// can be read out to a driver in either language.
String formatCoordinates(LatLng point) =>
    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

/// The tile ground for every map in the app. In the dark appearance the
/// tiles are inverted rather than left as a bright slab in a dark screen.
class MapTiles extends StatelessWidget {
  const MapTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: AppConfig.mapTileUrl,
      userAgentPackageName: AppConfig.mapUserAgentPackage,
      tileBuilder: dark ? darkModeTileBuilder : null,
    );
  }
}

/// The attribution OpenStreetMap's licence requires wherever its tiles show.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.https('www.openstreetmap.org', '/copyright'),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSpace.xs + 2,
          vertical: DesignSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.tape.withValues(alpha: .86),
          borderRadius: BorderRadius.circular(DesignRadius.slot),
        ),
        child: Text(
          context.l10n.mapAttribution,
          textDirection: TextDirection.ltr,
          style: DesignTypography.fibreLine(colors.inkSecondary, size: 10),
        ),
      ),
    );
  }
}

/// The pin, drawn in the label's own grammar: a disc with a dot inside on a
/// short stem, and a bar beneath marking the exact point. While the map
/// moves the pin lifts off its bar, so the customer sees where it will land;
/// it drops back when the map settles.
class LocationPin extends StatelessWidget {
  const LocationPin({super.key, this.lifted = false});

  final bool lifted;

  static const size = Size(44, 60);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.fromSize(
      size: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: lifted ? 1 : 0),
        duration: reduceMotion ? Duration.zero : DesignMotion.quick,
        curve: lifted ? DesignMotion.enter : DesignMotion.settle,
        builder: (context, lift, _) => CustomPaint(
          painter: _PinPainter(
            ink: colors.ink,
            ground: colors.tape,
            mark: colors.tint,
            lift: lift,
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({
    required this.ink,
    required this.ground,
    required this.mark,
    required this.lift,
  });

  final Color ink;
  final Color ground;
  final Color mark;
  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final tip = size.height - 3;
    final rise = 10 * lift;

    // The bar beneath: the exact point. It stays put while the pin lifts.
    canvas.drawLine(
      Offset(cx - 7, tip),
      Offset(cx + 7, tip),
      Paint()
        ..color = Color.lerp(ink, mark, lift)!
        ..strokeWidth = DesignRule.heavy + lift
        ..strokeCap = StrokeCap.round,
    );

    const radius = 13.0;
    final head = Offset(cx, radius + 3 - rise + 10);
    final stemEnd = Offset(cx, tip - 3 - rise * .2);

    canvas
      ..drawLine(
        head.translate(0, radius - 1),
        stemEnd,
        Paint()
          ..color = ink
          ..strokeWidth = DesignRule.heavy + .5
          ..strokeCap = StrokeCap.round,
      )
      // A tape halo keeps the pin legible on any tile, light or dark.
      ..drawCircle(head, radius + 2, Paint()..color = ground)
      ..drawCircle(head, radius, Paint()..color = ink)
      ..drawCircle(head, 5.5, Paint()..color = ground)
      ..drawCircle(head, 2.5, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.lift != lift ||
      old.ink != ink ||
      old.ground != ground ||
      old.mark != mark;
}
