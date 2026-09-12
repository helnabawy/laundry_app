import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White page header from the designs: back arrow at the start, centered
/// title + subtitle, and optional step dots for the order wizard.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.step,
    this.totalSteps = 4,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;

  /// 1-based step; dots are hidden when null.
  final int? step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showBack)
                    PositionedDirectional(
                      start: 0,
                      child: IconButton(
                        // arrow_back mirrors automatically in RTL.
                        icon: const Icon(Icons.arrow_back),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                      ),
                    ),
                ],
              ),
              if (step != null) ...[
                const SizedBox(height: 16),
                _StepDots(step: step!, total: totalSteps),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= step ? AppColors.ink : AppColors.line,
            ),
          ),
      ],
    );
  }
}
