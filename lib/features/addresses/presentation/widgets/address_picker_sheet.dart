import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chooseAddress,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => AddressTile(
                    address: addresses[i],
                    selected: addresses[i] == selected,
                    onTap: () => Navigator.pop(sheetContext, addresses[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addAddress),
                onPressed: () async {
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
      );
    },
  );
}
