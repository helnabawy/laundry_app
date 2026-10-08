import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment_info.dart';

/// The mock backend's stand-in for a provider's hosted checkout. Resolves
/// true for a successful payment, false for a decline, null when dismissed
/// (the payment stays pending, as when a customer closes a real page).
Future<bool?> showMockGatewaySheet(BuildContext context, PaymentInfo payment) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final colors = sheetContext.colors;
      final text = Theme.of(sheetContext).textTheme;
      final amount = AppFormat.of(sheetContext).money(payment.amount);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.sm,
            DesignSpace.gutter,
            DesignSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(CupertinoIcons.lock, color: colors.ink),
              const SizedBox(height: DesignSpace.sm),
              Text(
                l10n.mockGatewayTitle(payment.provider.brand),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: DesignSpace.xs),
              Text(
                l10n.mockGatewayBody,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: colors.inkSecondary),
              ),
              const SizedBox(height: DesignSpace.xxl),
              ActionButton(
                label: l10n.payAmount(amount),
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: DesignSpace.sm),
              ActionButton(
                label: l10n.mockGatewayDecline,
                tone: ActionTone.secondary,
                onPressed: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        ),
      );
    },
  );
}
