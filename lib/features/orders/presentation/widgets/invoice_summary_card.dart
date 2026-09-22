import 'package:flutter/cupertino.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.card => l10n.card,
    PaymentMethod.cashOnDelivery => l10n.cashOnDelivery,
  };
}

/// The invoice teaser on the tracking page, tapping through to the full one.
class InvoiceSummaryCard extends StatelessWidget {
  const InvoiceSummaryCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    return LabelGroup(
      children: [
        LabelRow(
          title: l10n.invoiceNumber(invoice.id.toUpperCase()),
          subtitle: invoice.paid
              ? l10n.paidWith(invoice.paymentMethod?.label(l10n) ?? '')
              : l10n.unpaid,
          value: format.money(invoice.total),
          trailing: Icon(
            CupertinoIcons.chevron_forward,
            color: colors.inkTertiary,
          ),
          onTap: onTap,
        ),
      ],
    );
  }
}
