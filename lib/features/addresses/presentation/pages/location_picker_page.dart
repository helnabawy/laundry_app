import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../widgets/location_map.dart';

/// Opens the pin picker full-screen and resolves with the chosen point, or
/// null if the customer backs out.
///
/// Pushed on the root navigator rather than through the router: the address
/// fields also appear in first-run profile completion, where the router only
/// allows the profile screen itself.
Future<LatLng?> pickLocation(BuildContext context, {LatLng? initial}) =>
    Navigator.of(context, rootNavigator: true).push<LatLng>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerPage(initial: initial),
      ),
    );

/// The map moves; the pin stays in the middle. Moving the ground under a
/// fixed pin is steadier one-handed than dragging a small marker around.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial});

  final LatLng? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _map = MapController();
  late LatLng _center = widget.initial ?? defaultMapCenter;
  var _moving = false;
  var _locating = false;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    // With no pin yet, jump to the customer's position — but only when
    // they've already granted access. The prompt waits for their tap.
    if (widget.initial == null) unawaited(_locate(prompt: false));
  }

  @override
  void dispose() {
    _settle?.cancel();
    _map.dispose();
    super.dispose();
  }

  void _onMoved(MapCamera camera, bool hasGesture) {
    _settle?.cancel();
    setState(() {
      _center = camera.center;
      _moving = true;
    });
    _settle = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _moving = false);
      if (hasGesture) HapticFeedback.selectionClick();
    });
  }

  Future<void> _locate({required bool prompt}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    void tell(String message, {bool settings = false}) {
      if (!prompt) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: settings
                ? SnackBarAction(
                    label: l10n.openSettings,
                    onPressed: Geolocator.openAppSettings,
                  )
                : null,
          ),
        );
    }

    setState(() => _locating = prompt);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return tell(l10n.locationServiceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return tell(l10n.locationPermissionDenied);
        case LocationPermission.deniedForever:
          return tell(l10n.locationPermissionDenied, settings: true);
        case LocationPermission.whileInUse ||
            LocationPermission.always ||
            LocationPermission.unableToDetermine:
          break;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      _map.move(LatLng(position.latitude, position.longitude), pinZoom);
    } on Exception {
      tell(l10n.locationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return DetailPage(
      title: l10n.pickLocationTitle,
      bottomBar: ActionBar(
        note: l10n.pickLocationHint,
        children: [
          ActionButton(
            label: l10n.confirmLocation,
            onPressed: _moving ? null : () => Navigator.pop(context, _center),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: l10n.pickLocationHint,
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: widget.initial == null ? 12 : pinZoom,
                  minZoom: 5,
                  maxZoom: 19,
                  backgroundColor: colors.tapeSunken,
                  // No rotation: a map that turns under one thumb loses its
                  // north, and the pin is about position, not heading.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onPositionChanged: _onMoved,
                ),
                children: const [MapTiles()],
              ),
            ),
          ),

          // The pin's tip sits exactly on the map's centre.
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, -LocationPin.size.height / 2 + 3),
                child: LocationPin(lifted: _moving),
              ),
            ),
          ),

          // The reading, printed on a strip of tape over the map.
          PositionedDirectional(
            top: DesignSpace.md,
            start: DesignSpace.gutter,
            end: DesignSpace.gutter,
            child: Center(
              child: _CoordinateTag(point: _center, moving: _moving),
            ),
          ),

          PositionedDirectional(
            bottom: DesignSpace.lg,
            end: DesignSpace.gutter,
            child: _LocateButton(
              busy: _locating,
              label: l10n.useMyLocation,
              onPressed: () => _locate(prompt: true),
            ),
          ),

          const PositionedDirectional(
            bottom: DesignSpace.sm,
            start: DesignSpace.sm,
            child: MapAttribution(),
          ),
        ],
      ),
    );
  }
}

class _CoordinateTag extends StatelessWidget {
  const _CoordinateTag({required this.point, required this.moving});

  final LatLng point;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpace.md,
        vertical: DesignSpace.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.tape,
        borderRadius: BorderRadius.circular(DesignRadius.slot),
        border: Border.all(color: colors.rule, width: DesignRule.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.scope,
            size: 14,
            color: moving ? colors.tint : colors.inkSecondary,
          ),
          const SizedBox(width: DesignSpace.xs + 2),
          Text(
            formatCoordinates(point),
            textDirection: TextDirection.ltr,
            style: DesignTypography.numeric(
              colors.ink,
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: colors.tape,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignRadius.control),
            side: BorderSide(color: colors.ruleStrong),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy ? null : onPressed,
            child: SizedBox.square(
              dimension: 52,
              child: Center(
                child: busy
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: DesignRule.heavy,
                          color: colors.ink,
                        ),
                      )
                    : Icon(
                        CupertinoIcons.location_fill,
                        color: colors.tint,
                        size: 22,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
