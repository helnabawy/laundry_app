import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../addresses/presentation/widgets/address_tile.dart';
import '../../domain/entities/laundry_order.dart';
import '../utils/order_status_x.dart';

/// Replaces the wizard body once the order is created: the label is printed,
/// the strip starts at stage one, and the amount slot is held open.
class OrderConfirmationView extends StatelessWidget {
  const OrderConfirmationView({super.key, required this.order});

  final LaundryOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    return Scaffold(
      backgroundColor: colors.tape,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // The outcome, photographed: what comes back, folded.
            PhotoBand(
              image: Photo.confirmFolded,
              aspectRatio: 4 / 3,
              scrim: ScrimWeight.heavy,
              child: Padding(
                padding: const EdgeInsets.all(DesignSpace.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.orderPlaced,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: const Color(0xFFFFFFFF)),
                    ),
                    const SizedBox(height: DesignSpace.xs),
                    Text(
                      l10n.orderPlacedSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: const Color(0xE6FFFFFF)),
                    ),
                  ],
                ),
              ),
            ),
            CustodyStrip(
              stages: custodyStagesFor(
                order.status,
                l10n,
                isShopOrder: order.lines.isEmpty,
              ),
              caption:
                  '${l10n.orderNumberLabel} ${order.number} · '
                  '${order.tier.name}',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.gutter,
                DesignSpace.xxl,
                DesignSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SerialBlock(
                    serial: order.number.toString(),
                    caption: order.servicesLabel,
                  ),
                  const SizedBox(height: DesignSpace.xl),
                  FieldLine(label: l10n.levelLabel, value: order.tier.name),
                  const StitchRule(),
                  FieldLine(
                    label: l10n.pickupLabel,
                    value: format.slotWithDate(
                      order.pickupSlot.start,
                      order.pickupSlot.end,
                    ),
                  ),
                  const StitchRule(),
                  FieldLine(
                    label: l10n.deliveryLabel,
                    value: format.slotWithDate(
                      order.deliverySlot.start,
                      order.deliverySlot.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignSpace.xl),
            LabelGroup(
              heading: l10n.addressFieldLabel,
              children: [AddressTile(address: order.address)],
            ),
            // Shop-flow orders already have a fixed, confirmed price at this
            // point (unlike a wizard-flow order, priced later by the
            // facility), so the itemized breakdown can be shown immediately.
            if (order.invoice case final invoice?) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSpace.gutter,
                  DesignSpace.xxl,
                  DesignSpace.gutter,
                  0,
                ),
                child: LabelGroup(
                  heading: l10n.itemsDetails,
                  children: [
                    for (final item in invoice.items)
                      LabelRow(
                        title: item.name,
                        subtitle:
                            '${item.quantity} \u00d7 ${format.money(item.unitPrice)}',
                        value: format.money(item.total),
                      ),
                  ],
                ),
              ),
              if (invoice.vipSurcharge > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSpace.gutter,
                    DesignSpace.xl,
                    DesignSpace.gutter,
                    0,
                  ),
                  child: FieldLine(
                    label: l10n.vipSurchargeLabel,
                    value: format.money(invoice.vipSurcharge),
                  ),
                ),
              if (invoice.codFee > 0)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignSpace.gutter,
                    invoice.vipSurcharge > 0 ? DesignSpace.sm : DesignSpace.xl,
                    DesignSpace.gutter,
                    0,
                  ),
                  child: FieldLine(
                    label: l10n.codFeeLabel,
                    value: format.money(invoice.codFee),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.gutter,
                DesignSpace.xxl,
                DesignSpace.gutter,
                DesignSpace.huge,
              ),
              child: AmountSlot(
                label: l10n.total,
                placeholder: l10n.currencyAed('\u2014.\u2014\u2014'),
                amount: order.invoice != null
                    ? format.money(order.invoice!.total)
                    : null,
                pendingNote: order.invoice != null
                    ? null
                    : l10n.invoiceAfterInspectionBody,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionBar(
        children: [
          ActionButton(
            label: l10n.trackOrder,
            onPressed: () =>
                context.pushReplacement(Routes.orderDetail(order.id)),
          ),
          ActionButton(
            label: l10n.backToHome,
            tone: ActionTone.secondary,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
