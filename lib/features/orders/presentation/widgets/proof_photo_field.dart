import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// The camera slot a driver fills at a stop: proof of delivery, or evidence
/// that nobody was there to hand the items over.
///
/// Tapping opens the rear camera; once taken, the slot shows the photo and a
/// second tap retakes it. Camera problems are printed under the slot rather
/// than in a dialog, so the field works the same inside a sheet.
class ProofPhotoField extends StatefulWidget {
  const ProofPhotoField({
    super.key,
    required this.photoPath,
    required this.onChanged,
    required this.prompt,
  });

  /// The captured image on the device, or null before the first shot.
  final String? photoPath;
  final ValueChanged<String> onChanged;

  /// What the empty slot asks for, e.g. "Take a photo (optional)".
  final String prompt;

  @override
  State<ProofPhotoField> createState() => _ProofPhotoFieldState();
}

class _ProofPhotoFieldState extends State<ProofPhotoField> {
  static final _picker = ImagePicker();

  var _busy = false;
  String? _error;

  Future<void> _capture() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final path = await _pick(ImageSource.camera);
      if (path != null) widget.onChanged(path);
    } on PlatformException catch (e) {
      if (kDebugMode && e.code == 'no_available_camera') {
        // The simulator has no camera; development builds take a library
        // image instead so the flow can still be walked through. Release
        // builds never do, or a driver could submit an old photo.
        final path = await _pick(ImageSource.gallery);
        if (path != null) widget.onChanged(path);
      } else {
        error = e.code == 'camera_access_denied'
            ? l10n.cameraAccessDenied
            : l10n.cameraUnavailable;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  /// Photos are evidence, not portraits: capped in size so they upload
  /// quickly on a mobile connection at the door.
  Future<String?> _pick(ImageSource source) async => (await _picker.pickImage(
    source: source,
    preferredCameraDevice: CameraDevice.rear,
    maxWidth: 1600,
    imageQuality: 70,
  ))?.path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final path = widget.photoPath;
    final label = path != null ? l10n.retakePhoto : widget.prompt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _capture,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignRadius.panel),
              child: path != null
                  ? _Taken(path: path, label: label)
                  : _Empty(label: label, busy: _busy),
            ),
          ),
        ),
        if (_error case final message?) ...[
          const SizedBox(height: DesignSpace.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.signal),
          ),
        ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.label, required this.busy});

  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DesignSpace.xxl),
      decoration: BoxDecoration(
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(DesignRadius.panel),
      ),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 26,
            child: busy
                ? const CupertinoActivityIndicator()
                : Icon(
                    CupertinoIcons.camera,
                    color: colors.inkTertiary,
                    size: 26,
                  ),
          ),
          const SizedBox(height: DesignSpace.sm),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: DesignTypography.stamp(colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

/// The photo itself, with the retake prompt printed over its foot.
class _Taken extends StatelessWidget {
  const _Taken({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            // Decode near display size, not the camera's full resolution.
            cacheHeight: 540,
            errorBuilder: (context, _, _) =>
                ColoredBox(color: colors.tapeRecessed),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.md,
                DesignSpace.xl,
                DesignSpace.md,
                DesignSpace.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x00000000),
                    const Color(0xFF000000).withValues(alpha: .72),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.camera_rotate,
                    color: Color(0xFFFFFFFF),
                    size: 18,
                  ),
                  const SizedBox(width: DesignSpace.sm),
                  Text(
                    label.toUpperCase(),
                    style: DesignTypography.stamp(const Color(0xFFFFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
