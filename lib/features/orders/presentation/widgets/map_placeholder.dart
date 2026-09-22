import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../addresses/domain/entities/address.dart';
import '../utils/launchers.dart';

/// No Maps SDK ships in this build, so rather than faking a map we print the
/// address as a routing block and hand navigation to the device's real maps
/// app. An honest field beats a decorative one the driver cannot trust.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final lines = [
      '${address.area}${l10n.listSeparator}${address.city}',
      l10n.buildingApartment(address.building, address.apartment),
      if (address.floor case final floor?) '${l10n.floor}: $floor',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tapeRecessed,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(DesignRadius.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.placemark, color: colors.ink, size: 22),
                const SizedBox(width: DesignSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addressFieldLabel.toUpperCase(),
                        style: DesignTypography.stamp(colors.inkSecondary),
                      ),
                      const SizedBox(height: DesignSpace.xs),
                      for (final line in lines)
                        Text(
                          line,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignSpace.md),
            const StitchRule.dashed(),
            const SizedBox(height: DesignSpace.sm),
            TintAction(
              label: l10n.openInMaps,
              onPressed: () => launchMaps(address),
              trailing: const Icon(CupertinoIcons.arrow_up_right_square),
            ),
          ],
        ),
      ),
    );
  }
}
