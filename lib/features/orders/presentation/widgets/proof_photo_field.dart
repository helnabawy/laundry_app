import 'package:flutter/cupertino.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// The camera slot a driver fills at a stop: proof of delivery, or evidence
/// that nobody was there to hand the items over.
class ProofPhotoField extends StatelessWidget {
  const ProofPhotoField({
    super.key,
    required this.hasPhoto,
    required this.onTap,
    required this.prompt,
  });

  final bool hasPhoto;
  final VoidCallback onTap;

  /// What the empty slot asks for, e.g. "Take a photo (optional)".
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Semantics(
      button: true,
      label: hasPhoto ? l10n.retakePhoto : prompt,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignSpace.xxl),
          decoration: BoxDecoration(
            color: hasPhoto ? colors.tapeRecessed : null,
            border: Border.all(color: colors.rule),
            borderRadius: BorderRadius.circular(DesignRadius.panel),
          ),
          child: Column(
            children: [
              Icon(
                hasPhoto ? CupertinoIcons.checkmark_alt : CupertinoIcons.camera,
                color: hasPhoto ? colors.ink : colors.inkTertiary,
                size: 26,
              ),
              const SizedBox(height: DesignSpace.sm),
              Text(
                (hasPhoto ? l10n.retakePhoto : prompt).toUpperCase(),
                textAlign: TextAlign.center,
                style: DesignTypography.stamp(colors.inkSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
