import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BannerTone { info, warning, success }

/// Tinted notice box ("final price after inspection", laundry notes, ...).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = BannerTone.info,
    this.leading,
  });

  final String title;
  final String? message;
  final BannerTone tone;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final (bg, border, titleColor, bodyColor) = switch (tone) {
      BannerTone.info => (
        AppColors.tealSoft.withValues(alpha: .6),
        AppColors.line,
        AppColors.ink,
        AppColors.muted,
      ),
      BannerTone.warning => (
        AppColors.goldSoft,
        AppColors.goldBorder,
        const Color(0xFF8A6220),
        AppColors.gold,
      ),
      BannerTone.success => (
        AppColors.successSoft,
        AppColors.success.withValues(alpha: .25),
        const Color(0xFF16734D),
        AppColors.success,
      ),
    };
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: text.bodySmall?.copyWith(color: bodyColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
