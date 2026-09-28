import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../cubit/cart_cubit.dart';
import 'qty_stepper.dart';

/// The cart, as a modal — mirrors [showConfirmSheet]'s chrome: a titled
/// sheet, SafeArea padding, and the page's commit at the foot.
Future<void> showCartSheet(BuildContext context) {
  final cart = context.read<CartCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: cart,
      child: const _CartSheetBody(),
    ),
  );
}

class _CartSheetBody extends StatelessWidget {
  const _CartSheetBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);
    final cart = context.watch<CartCubit>().state;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSpace.gutter,
          DesignSpace.sm,
          DesignSpace.gutter,
          DesignSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cartTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignSpace.lg),
            if (cart.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DesignSpace.xl),
                child: Text(
                  l10n.cartEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.inkSecondary),
                ),
              )
            else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, _) => const StitchRule(),
                  itemBuilder: (context, i) {
                    final line = cart.lines[i];
                    final cubit = context.read<CartCubit>();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignSpace.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  line.product.name,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: DesignSpace.xxs),
                                Text(
                                  format.money(line.lineTotal),
                                  style: DesignTypography.numeric(
                                    colors.ink,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: DesignSpace.md),
                          QtyStepper(
                            quantity: line.quantity,
                            onIncrement: () =>
                                cubit.increment(line.product.id),
                            onDecrement: () =>
                                cubit.decrement(line.product.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const StitchRule.dashed(),
              const SizedBox(height: DesignSpace.md),
              FieldLine(
                label: l10n.subtotal,
                value: format.money(cart.total),
                emphasised: true,
              ),
              const SizedBox(height: DesignSpace.lg),
              ActionButton(
                label: l10n.checkoutTitle,
                onPressed: () {
                  Navigator.pop(context);
                  context.push(Routes.checkout);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
