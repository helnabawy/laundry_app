import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../addresses/presentation/widgets/address_tile.dart';
import '../../../orders/presentation/utils/category_icons.dart';
import '../../domain/entities/cart.dart';
import '../cubit/checkout_cubit.dart';

/// The undo window of a one-tap shop-order reorder: what is about to be
/// ordered — the repopulated cart, schedule and address — a draining count,
/// and the way out. Nothing has been sent while this shows.
class ReorderCountdownView extends StatelessWidget {
  const ReorderCountdownView({
    super.key,
    required this.state,
    required this.cubit,
    required this.cart,
  });

  final CheckoutState state;
  final CheckoutCubit cubit;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);
    final pickup = state.pickupSlot!;
    final delivery = state.deliverySlot!;
    final address = state.address!;
    final window = cubit.undoWindow;

    return DetailPage(
      title: l10n.reorderNoticeTitle(state.reorderOf.toString()),
      bottomBar: ActionBar(
        children: [
          ActionButton(
            label: l10n.undo,
            icon: const Icon(CupertinoIcons.arrow_uturn_left),
            // The enclosing `PopScope` turns this pop into the actual undo.
            onPressed: () => context.pop(),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: DesignSpace.huge),
        children: [
          TapeBand(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpace.gutter,
              vertical: DesignSpace.xxl,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: window,
              builder: (context, left, _) {
                final seconds = (left * window.inMilliseconds / 1000).ceil();
                return Column(
                  children: [
                    Text(
                      l10n.reorderCountdownLead.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: DesignTypography.stamp(colors.inkSecondary),
                    ),
                    const SizedBox(height: DesignSpace.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '$seconds',
                        style: DesignTypography.serial(colors.ink, size: 56),
                      ),
                    ),
                    const SizedBox(height: DesignSpace.lg),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignRadius.slot),
                      child: LinearProgressIndicator(
                        value: left,
                        minHeight: 3,
                        color: colors.ink,
                        backgroundColor: colors.rule,
                      ),
                    ),
                    const SizedBox(height: DesignSpace.md),
                    Text(
                      l10n.reorderUndoHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.inkSecondary),
                    ),
                  ],
                );
              },
            ),
          ),
          LabelGroup(
            children: [
              for (final line in cart.lines)
                LabelRow(
                  leading: CareGlyphIcon(
                    categoryGlyph(line.product.categoryId),
                    color: colors.ink,
                    size: 26,
                  ),
                  title: line.product.name,
                  subtitle:
                      '${line.quantity} × ${format.money(line.product.unitPrice)}',
                  value: format.money(line.lineTotal),
                ),
              LabelRow(
                title: l10n.pickupTime,
                subtitle: format.slotRelative(pickup.start, pickup.end),
              ),
              LabelRow(
                title: l10n.deliveryTime,
                subtitle: format.slotRelative(delivery.start, delivery.end),
              ),
              LabelRow(
                title: address.name(l10n),
                subtitle: address.summary(l10n),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpace.gutter,
              vertical: DesignSpace.md,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TintAction(
                label: l10n.changeTimes,
                onPressed: cubit.editReorder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
