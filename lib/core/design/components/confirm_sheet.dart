import 'package:flutter/material.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import 'app_buttons.dart';

/// Asks before a consequential action. The entry point that opened it stays
/// in the tint; only the commit here carries [ActionTone.danger], so the
/// thread red appears at the moment of consequence and nowhere before it.
///
/// Resolves true only when the action was confirmed.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      final text = Theme.of(sheetContext).textTheme;
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
              Text(title, textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: DesignSpace.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: colors.inkSecondary),
              ),
              const SizedBox(height: DesignSpace.xxl),
              ActionButton(
                label: confirmLabel,
                tone: ActionTone.danger,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: DesignSpace.sm),
              ActionButton(
                label: cancelLabel,
                tone: ActionTone.secondary,
                onPressed: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
