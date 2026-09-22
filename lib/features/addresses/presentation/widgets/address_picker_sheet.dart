import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../domain/entities/address.dart';
import 'address_tile.dart';

/// Lets the customer pick one of their saved addresses or add a new one
/// (step 2.6). Resolves to the chosen [Address], or null if dismissed.
Future<Address?> showAddressPicker(
  BuildContext context, {
  required List<Address> addresses,
  Address? selected,
}) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final colors = sheetContext.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.gutter,
                0,
                DesignSpace.gutter,
                DesignSpace.md,
              ),
              child: Text(
                l10n.chooseAddress.toUpperCase(),
                style: DesignTypography.stamp(colors.inkSecondary),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: LabelGroup(
                  children: [
                    for (final address in addresses)
                      AddressTile(
                        address: address,
                        selected: address == selected,
                        onTap: () => Navigator.pop(sheetContext, address),
                      ),
                    LabelRow(
                      leading: Icon(CupertinoIcons.add, color: colors.tint),
                      title: l10n.addAddress,
                      onTap: () async {
                        final created = await sheetContext.push<Address>(
                          Routes.addAddress,
                        );
                        if (created != null && sheetContext.mounted) {
                          Navigator.pop(sheetContext, created);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignSpace.lg),
          ],
        ),
      );
    },
  );
}
