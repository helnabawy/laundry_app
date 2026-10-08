import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../shop/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/laundry.dart';
import '../cubit/laundry_cubit.dart';

/// "Choose a laundry": shown after sign-in until the customer picks one,
/// and again from Home's "Change". With a single laundry it picks itself.
class LaundryPickerPage extends StatefulWidget {
  const LaundryPickerPage({super.key});

  @override
  State<LaundryPickerPage> createState() => _LaundryPickerPageState();
}

class _LaundryPickerPageState extends State<LaundryPickerPage> {
  @override
  void initState() {
    super.initState();
    sl<LaundryCubit>().load();
  }

  Future<void> _choose(BuildContext context, Laundry laundry) async {
    final laundries = sl<LaundryCubit>();
    final cart = sl<CartCubit>();
    final previous = laundries.state.selected;
    final switching = previous != null && previous.id != laundry.id;
    if (switching && !cart.state.isEmpty) {
      final l10n = context.l10n;
      final confirmed = await showConfirmSheet(
        context,
        title: l10n.laundrySwitchTitle,
        message: l10n.laundrySwitchMessage(previous.name),
        confirmLabel: l10n.laundrySwitchConfirm,
        cancelLabel: l10n.cancel,
      );
      if (!confirmed) return;
    }
    await laundries.choose(laundry);
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final cubit = sl<LaundryCubit>();

    return BlocConsumer<LaundryCubit, LaundryState>(
      bloc: cubit,
      // The only laundry was picked for the customer: nothing to choose.
      listenWhen: (before, after) =>
          before.loading && !after.loading && after.laundries.length == 1,
      listener: (context, state) {
        if (state.selected != null && !context.canPop()) {
          context.go(Routes.customerHome);
        }
      },
      builder: (context, state) => DetailPage(
        title: l10n.chooseLaundryTitle,
        child: switch (state) {
          LaundryState(laundries: [], loading: true) => const LoadingView(),
          LaundryState(laundries: [], failure: final failure?) => ErrorView(
            message: failure.localized(l10n),
            onRetry: cubit.load,
            retryLabel: l10n.retry,
          ),
          LaundryState(laundries: []) => ErrorView(
            message: l10n.laundryNoneAvailable,
            onRetry: cubit.load,
            retryLabel: l10n.retry,
          ),
          LaundryState(:final laundries, :final selected) => RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.only(top: DesignSpace.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSpace.gutter,
                    0,
                    DesignSpace.gutter,
                    DesignSpace.lg,
                  ),
                  child: Text(
                    l10n.chooseLaundryIntro,
                    style: text.bodyMedium?.copyWith(
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
                LabelGroup(
                  children: [
                    for (final laundry in laundries)
                      LabelRow(
                        leading: Icon(
                          CupertinoIcons.building_2_fill,
                          color: colors.tint,
                        ),
                        title: laundry.name,
                        subtitle: [
                          laundry.locality,
                          laundry.address,
                        ].whereType<String>().join(' · '),
                        selected: laundry.id == selected?.id,
                        value: laundry.id == selected?.id
                            ? l10n.laundryCurrent
                            : null,
                        trailing: const Icon(CupertinoIcons.chevron_forward),
                        onTap: () => _choose(context, laundry),
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
