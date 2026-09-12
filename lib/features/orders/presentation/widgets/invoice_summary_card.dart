import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/invoice.dart';

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.card => l10n.card,
    PaymentMethod.cashOnDelivery => l10n.cashOnDelivery,
  };
}

/// The invoice teaser at the bottom of the tracking page (plan §8.1, screen
/// "تتبع الطلب"), tap-through to the full invoice.
class InvoiceSummaryCard extends StatelessWidget {
  const InvoiceSummaryCard({super.key, required this.invoice, required this.onTap});

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.invoiceNumber(invoice.id.toUpperCase()),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.paid
                      ? l10n.paidWith(invoice.paymentMethod?.label(l10n) ?? '')
                      : l10n.unpaid,
                  style: TextStyle(
                    color: invoice.paid ? AppColors.success : AppColors.gold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            format.money(invoice.total),
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Icon(Icons.chevron_left, color: AppColors.faint),
        ],
      ),
    );
  }
}
