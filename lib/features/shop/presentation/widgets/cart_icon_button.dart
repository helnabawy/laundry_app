import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../cubit/cart_cubit.dart';
import 'cart_sheet.dart';

/// The cart's own top-bar entry point — the same squared-badge grammar
/// [NotificationBell] uses for unread mail, carrying the item count instead.
/// Reads the shared [CartCubit] singleton directly, so it works wherever
/// that cubit is provided above it (the customer shell provides it once,
/// for every tab).
class OpenCartButton extends StatelessWidget {
  const OpenCartButton({super.key, this.color, this.ground});

  /// The bag's ink; defaults to the page ink.
  final Color? color;

  /// What the button sits on, used to cut the badge free of the bag stroke.
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final itemCount = context.select<CartCubit, int>((c) => c.state.itemCount);
    return CartIconButton(
      itemCount: itemCount,
      color: color,
      ground: ground,
      onPressed: () => showCartSheet(context),
    );
  }
}

/// The bag glyph itself, with its item-count badge — split from
/// [OpenCartButton] so it can be pumped in a test without a [CartCubit].
class CartIconButton extends StatelessWidget {
  const CartIconButton({
    super.key,
    required this.itemCount,
    required this.onPressed,
    this.color,
    this.ground,
  });

  final int itemCount;
  final VoidCallback onPressed;
  final Color? color;
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final ink = color ?? colors.ink;
    final hasItems = itemCount > 0;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.cartItemsLabel(itemCount),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: DesignSpace.touchTarget,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                hasItems ? CupertinoIcons.bag_fill : CupertinoIcons.bag,
                color: ink,
                size: 24,
              ),
              if (hasItems)
                PositionedDirectional(
                  top: 5,
                  end: 3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.ink,
                      borderRadius: BorderRadius.circular(DesignRadius.slot),
                      border: Border.all(
                        color: ground ?? colors.tape,
                        width: DesignRule.medium,
                      ),
                    ),
                    child: Text(
                      itemCount > 9 ? '9+' : '$itemCount',
                      textScaler: TextScaler.noScaling,
                      style: DesignTypography.numeric(
                        colors.onInk,
                        size: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
