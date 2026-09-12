import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/address.dart';

extension AddressDisplay on Address {
  /// `الخالدية، أبوظبي`
  String title(AppLocalizations l10n) => '$area${l10n.listSeparator}$city';

  /// `مبنى 12، شقة 704`
  String subtitle(AppLocalizations l10n) =>
      l10n.buildingApartment(building, apartment);
}

class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.address,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final Address address;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderColor: selected ? AppColors.ink : AppColors.line,
      borderWidth: selected ? 2 : 1,
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.title(l10n),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  address.subtitle(l10n),
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
