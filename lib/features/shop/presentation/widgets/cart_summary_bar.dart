import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../cubit/cart_cubit.dart';
import 'cart_sheet.dart';

/// A pinned bottom bar — visible only once the cart holds something — that
/// names the running total and opens the [showCartSheet] modal.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final cart = context.watch<CartCubit>().state;

    if (cart.isEmpty) return const SizedBox.shrink();

    return ActionBar(
      children: [
        ActionButton(
          label: l10n.viewCartWithCount(cart.itemCount, format.money(cart.total)),
          onPressed: () => showCartSheet(context),
        ),
      ],
    );
  }
}
