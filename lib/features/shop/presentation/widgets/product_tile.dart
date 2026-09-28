import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/product.dart';
import '../../../orders/presentation/utils/category_icons.dart';
import '../../domain/entities/cart.dart';
import '../cubit/cart_cubit.dart';
import 'qty_stepper.dart';

/// One product in the shop grid: a bordered label card in the system's own
/// vocabulary — a sunken fallback image area, the name, the price in its own
/// numeric slot, and a quantity stepper wired straight to the cart.
///
/// The image area is flexible rather than a fixed square: the grid gives
/// every tile a fixed overall height, and the name/price/stepper below it
/// need a guaranteed amount of that regardless of Dynamic Type scale — a
/// forced 1:1 square image was tall enough to push the stepper past the
/// tile's bottom edge and off the hit-testable area entirely.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tape,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(DesignRadius.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tapeSunken,
                  borderRadius: BorderRadius.circular(DesignRadius.slot),
                ),
                child: Center(
                  child: CareGlyphIcon(
                    categoryGlyph(product.categoryId),
                    color: colors.inkTertiary,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignSpace.sm),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignSpace.xxs),
            Text(
              format.money(product.unitPrice),
              style: DesignTypography.numeric(colors.ink, size: 15),
            ),
            const SizedBox(height: DesignSpace.sm),
            if (!product.isActive)
              Text(
                l10n.productUnavailable.toUpperCase(),
                style: DesignTypography.stamp(colors.inkTertiary, size: 10.5),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: BlocSelector<CartCubit, Cart, int>(
                  selector: (cart) => cart.quantityOf(product.id) ?? 0,
                  builder: (context, quantity) {
                    final cart = context.read<CartCubit>();
                    return QtyStepper(
                      quantity: quantity,
                      onIncrement: () => quantity == 0
                          ? cart.add(product)
                          : cart.increment(product.id),
                      onDecrement: () => cart.decrement(product.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
