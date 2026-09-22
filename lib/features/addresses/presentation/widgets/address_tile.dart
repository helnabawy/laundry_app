import 'package:flutter/cupertino.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/address.dart';

extension AddressDisplay on Address {
  /// `Al Khalidiyah, Abu Dhabi`
  String title(AppLocalizations l10n) => '$area${l10n.listSeparator}$city';

  /// `Building 12, Apt 704`
  String subtitle(AppLocalizations l10n) =>
      l10n.buildingApartment(building, apartment);
}

/// An address, in the one label anatomy every row in the app uses.
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
    final colors = context.colors;
    return LabelRow(
      leading: Icon(
        CupertinoIcons.placemark,
        size: 21,
        color: selected ? colors.onInk : colors.ink,
      ),
      title: address.title(l10n),
      subtitle: address.subtitle(l10n),
      selected: selected,
      onTap: onTap,
      trailing:
          trailing ??
          (selected
              ? const Icon(CupertinoIcons.checkmark_alt)
              : (onTap == null
                    ? null
                    : const Icon(CupertinoIcons.chevron_forward))),
    );
  }
}
