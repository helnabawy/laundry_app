import 'package:flutter/cupertino.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/address.dart';

extension AddressKindDisplay on AddressKind {
  String localized(AppLocalizations l10n) => switch (this) {
    AddressKind.home => l10n.addressKindHome,
    AddressKind.work => l10n.addressKindWork,
    AddressKind.other => l10n.addressKindOther,
  };

  IconData get icon => switch (this) {
    AddressKind.home => CupertinoIcons.house,
    AddressKind.work => CupertinoIcons.briefcase,
    AddressKind.other => CupertinoIcons.placemark,
  };
}

extension AddressDisplay on Address {
  /// `Home`, `Work`, or the customer's own name for an "other" address.
  String name(AppLocalizations l10n) => switch (label?.trim()) {
    final own? when kind == AddressKind.other && own.isNotEmpty => own,
    _ => kind.localized(l10n),
  };

  /// `Al Khalidiyah, Abu Dhabi, Building 12, Apt 704`
  String summary(AppLocalizations l10n) => [
    area,
    city,
    l10n.buildingApartment(building, apartment),
  ].join(l10n.listSeparator);
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
        address.kind.icon,
        size: 21,
        color: selected ? colors.onInk : colors.ink,
      ),
      title: address.name(l10n),
      subtitle: address.summary(l10n),
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
