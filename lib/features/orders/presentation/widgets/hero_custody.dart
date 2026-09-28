import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/laundry_order.dart';
import '../utils/order_status_x.dart';
import 'vip_mark.dart';

/// The custody strip printed over cloth.
///
/// The photograph is the ground and the tape is what is printed on it — the
/// same relationship a care label has to the garment it is sewn into. The
/// serial sits on the image at full scale; the strip hangs below it on real
/// tape so the glyph row keeps its flat, readable field.
class HeroCustody extends StatelessWidget {
  const HeroCustody({super.key, required this.order});

  /// Null means nothing is in custody: the tape prints blank over the cloth.
  final LaundryOrder? order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final live = order;
    final vip = live?.tier.isVip ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhotoBand(
          image: Photo.heroLinen,
          // A wide band anchored to the bottom of the frame: the cloth fills
          // it and the treeline above is cropped away, so the photograph reads
          // as the product's own material rather than a location.
          aspectRatio: 1.9,
          alignment: Alignment.bottomCenter,
          scrim: ScrimWeight.light,
          semanticLabel: null,
          child: Padding(
            padding: const EdgeInsets.all(DesignSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // A VIP order carries its woven label sewn onto the cloth,
                // at the corner where a garment's own label would sit.
                if (vip) ...[
                  VipMark(
                    tier: live!.tier,
                    tone: WovenTone.tape,
                    compact: false,
                  ),
                  const Spacer(),
                ],
                if (live == null)
                  Text(
                    l10n.nothingInCustody.toUpperCase(),
                    style: DesignTypography.stamp(
                      const Color(0xFFFFFFFF),
                      size: 14,
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          live.number.toString(),
                          style: DesignTypography.serial(
                            const Color(0xFFFFFFFF),
                            size: 52,
                          ),
                        ),
                      ),
                      StatusStamp(
                        label: live.status.label(l10n),
                        tone: live.status.isFailure
                            ? StampTone.alert
                            : StampTone.field,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSpace.xs),
                  Text(
                    vip
                        ? live.servicesLabel
                        : '${live.servicesLabel} · ${live.tier.name}',
                    style: DesignTypography.fibreLine(
                      const Color(0xF2FFFFFF),
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (vip) const TwinStitch(),
        if (live == null)
          CustodyStrip.blank(
            stages: blankCustodyStages(l10n),
            caption: l10n.nothingInCustodyNote,
          )
        else
          CustodyStrip(
            stages: custodyStagesFor(
              live.status,
              l10n,
              isShopOrder: live.lines.isEmpty,
            ),
            caption: live.status.isActive
                ? l10n
                      .expectedDelivery(
                        format.slotRelative(
                          live.deliverySlot.start,
                          live.deliverySlot.end,
                        ),
                      )
                      .toUpperCase()
                : format
                      .slotWithDate(
                        live.deliverySlot.start,
                        live.deliverySlot.end,
                      )
                      .toUpperCase(),
          ),
      ],
    );
  }
}
