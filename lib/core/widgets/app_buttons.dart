import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ButtonTone { primary, accent }

/// Full-width filled button. `accent` is the teal "commit" action in the
/// designs (confirm order, pay, confirm pickup/delivery).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.tone = ButtonTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: tone == ButtonTone.accent
          ? FilledButton.styleFrom(backgroundColor: AppColors.teal)
          : null,
      // Keep the enabled look while loading, but swallow taps.
      onPressed: loading ? (onPressed == null ? null : () {}) : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

/// Pads the page's bottom action(s) above the home indicator.
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}
