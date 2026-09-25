import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../domain/entities/address.dart';
import '../cubit/addresses_cubit.dart';
import '../widgets/address_tile.dart';

/// "My addresses": every saved pickup address, each one editable.
class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressesCubit>()..load(),
      child: const _AddressesView(),
    );
  }
}

class _AddressesView extends StatelessWidget {
  const _AddressesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<AddressesCubit>();

    // Reload whatever happened on the form: added, edited or deleted.
    Future<void> open(String location, {Address? extra}) async {
      await context.push<Address>(location, extra: extra);
      await cubit.load();
    }

    return BlocBuilder<AddressesCubit, AddressesState>(
      builder: (context, state) => DetailPage(
        title: l10n.savedAddresses,
        child: switch (state) {
          AddressesState(addresses: [], loading: true) => const LoadingView(),
          AddressesState(addresses: [], failure: final failure?) => ErrorView(
            message: failure.localized(l10n),
            onRetry: cubit.load,
            retryLabel: l10n.retry,
          ),
          AddressesState(:final addresses) => RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.only(top: DesignSpace.lg),
              children: [
                LabelGroup(
                  children: [
                    for (final address in addresses)
                      AddressTile(
                        address: address,
                        onTap: () => open(
                          Routes.editAddress(address.id),
                          extra: address,
                        ),
                      ),
                    LabelRow(
                      leading: Icon(CupertinoIcons.add, color: colors.tint),
                      title: l10n.addAddress,
                      onTap: () => open(Routes.addAddress),
                    ),
                  ],
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}
