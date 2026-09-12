import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/labeled_rows.dart';
import '../../../addresses/presentation/widgets/address_tile.dart';
import '../../domain/entities/laundry_order.dart';

/// Plan §8.1 "تأكيد الطلب" — replaces the wizard body once the order is
/// created (step 2.7 / stage-2 close in §9).
class OrderConfirmationView extends StatelessWidget {
  const OrderConfirmationView({super.key, required this.order});

  final LaundryOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.successSoft,
                child: Icon(Icons.check_rounded, color: AppColors.success, size: 44),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.orderPlaced,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.orderPlacedSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            AppCard(
              color: AppColors.background,
              borderColor: AppColors.line,
              child: Column(
                children: [
                  KeyValueRow(
                    label: l10n.orderNumberLabel,
                    value: '#${order.number}',
                  ),
                  KeyValueRow(
                    label: l10n.serviceLabel,
                    value: '${order.category.name} · ${order.subService.name}',
                  ),
                  KeyValueRow(label: l10n.levelLabel, value: order.tier.name),
                  KeyValueRow(
                    label: l10n.pickupLabel,
                    value: format.slotWithDate(
                      order.pickupSlot.start,
                      order.pickupSlot.end,
                    ),
                  ),
                  KeyValueRow(
                    label: l10n.deliveryLabel,
                    value: format.slotWithDate(
                      order.deliverySlot.start,
                      order.deliverySlot.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AddressTile(address: order.address),
            const SizedBox(height: 20),
            InfoBanner(
              title: l10n.invoiceAfterInspection,
              message: l10n.invoiceAfterInspectionBody,
              tone: BannerTone.warning,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          PrimaryButton(
            label: l10n.trackOrder,
            onPressed: () => context.push(Routes.orderDetail(order.id)),
          ),
          SecondaryButton(
            label: l10n.backToHome,
            onPressed: () => context.go(Routes.customerHome),
          ),
        ],
      ),
    );
  }
}
