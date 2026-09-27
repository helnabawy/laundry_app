import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../pages/location_picker_page.dart';
import 'location_map.dart';

/// The address's pin. Empty, it is a reserved slot asking to be filled;
/// filled, it is a picture of the spot with its coordinates printed beneath,
/// and tapping either the picture or "Edit location" reopens the picker.
class LocationField extends StatelessWidget {
  const LocationField({super.key, required this.location});

  final ValueNotifier<LatLng?> location;

  Future<void> _pick(BuildContext context) async {
    final picked = await pickLocation(context, initial: location.value);
    if (picked != null) location.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignSpace.xl),
      child: ValueListenableBuilder(
        valueListenable: location,
        builder: (context, point, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.locationOnMap.toUpperCase(),
              style: DesignTypography.stamp(colors.inkSecondary),
            ),
            const SizedBox(height: DesignSpace.sm),
            AnimatedSwitcher(
              duration: DesignMotion.base,
              switchInCurve: DesignMotion.settle,
              switchOutCurve: DesignMotion.exit,
              child: point == null
                  ? _EmptySlot(
                      key: const ValueKey('empty'),
                      onTap: () => _pick(context),
                    )
                  : _PinnedPreview(
                      key: ValueKey(point),
                      point: point,
                      onEdit: () => _pick(context),
                      onRemove: () => location.value = null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Before a pin exists: the slot is drawn and held open, like the amount
/// before inspection — clearly waiting, never pretending.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      child: Material(
        color: colors.tapeSunken,
        borderRadius: BorderRadius.circular(DesignRadius.panel),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: CustomPaint(
            painter: _DashedFrame(colors.ruleStrong),
            child: Padding(
              padding: const EdgeInsets.all(DesignSpace.lg),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 48,
                    child: FittedBox(child: const LocationPin()),
                  ),
                  const SizedBox(width: DesignSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pinOnMap,
                          style: text.bodyLarge?.copyWith(
                            color: colors.tint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: DesignSpace.xxs),
                        Text(
                          l10n.pinOnMapNote,
                          style: text.bodySmall?.copyWith(
                            color: colors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    color: colors.inkTertiary,
                    size: 18,
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

class _PinnedPreview extends StatelessWidget {
  const _PinnedPreview({
    super.key,
    required this.point,
    required this.onEdit,
    required this.onRemove,
  });

  final LatLng point;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '${l10n.mapPreviewSemantics}. ${l10n.editLocation}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onEdit,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignRadius.panel),
                border: Border.all(color: colors.rule),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignRadius.panel),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      // A picture of the spot, not a second map to fiddle
                      // with: all gestures go to "edit" instead.
                      IgnorePointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: point,
                            initialZoom: pinZoom - 0.5,
                            backgroundColor: colors.tapeSunken,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: const [MapTiles()],
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, -LocationPin.size.height / 2 + 3),
                          child: const LocationPin(),
                        ),
                      ),
                      const PositionedDirectional(
                        bottom: DesignSpace.xs,
                        start: DesignSpace.xs,
                        child: MapAttribution(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignSpace.sm),
        Row(
          children: [
            Icon(CupertinoIcons.scope, size: 14, color: colors.inkSecondary),
            const SizedBox(width: DesignSpace.xs + 2),
            Expanded(
              child: Text(
                formatCoordinates(point),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: DesignTypography.numeric(
                  colors.inkSecondary,
                  size: 13,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            TintAction(label: l10n.removeLocation, onPressed: onRemove),
            const SizedBox(width: DesignSpace.lg),
            TintAction(label: l10n.editLocation, onPressed: onEdit),
          ],
        ),
      ],
    );
  }
}

/// A stitched frame: the reserved slot's edge, dashed like the rule under a
/// pending amount.
class _DashedFrame extends CustomPainter {
  const _DashedFrame(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = DesignRule.hair
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(DesignRadius.panel),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFrame old) => old.color != color;
}
