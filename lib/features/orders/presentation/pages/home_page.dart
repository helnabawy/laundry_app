import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../cubit/orders_cubit.dart';
import '../utils/category_icons.dart';
import '../widgets/hero_custody.dart';
import '../widgets/order_list_tile.dart';

/// The customer's first viewport.
///
/// The live order sits at ticket scale directly under the title: the strip,
/// the serial as matter, and the amount slot held open until the facility
/// prices it. With nothing in custody the strip prints blank and carries the
/// way in on its own tape.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onViewAllOrders});

  final VoidCallback onViewAllOrders;

  /// Opens the order flow and refreshes on the way back, so a just-placed
  /// order appears in the hero instead of a stale empty state.
  Future<void> _startOrder(BuildContext context) async {
    final cubit = context.read<OrdersCubit>();
    await context.push(Routes.orderNew);
    await cubit.load();
  }

  /// An order's status or invoice can change while its detail is open, so the
  /// hero and the lists are re-read rather than left asserting what was true
  /// when the screen was first built.
  Future<void> _openOrder(BuildContext context, String id) async {
    final cubit = context.read<OrdersCubit>();
    await context.push(Routes.orderDetail(id));
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<OrdersCubit>().state;
    final current = state.current;

    return LargeTitlePage(
      title: l10n.navHome,
      onRefresh: () => context.read<OrdersCubit>().load(),
      slivers: [
        if (state.loading && state.orders.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: DesignSpace.huge),
              child: LoadingView(),
            ),
          )
        else ...[
          SliverToBoxAdapter(child: HeroCustody(order: current)),
          if (current case final order?)
            SliverToBoxAdapter(
              child: CurrentOrderDetail(
                order: order,
                onTap: () => _openOrder(context, order.id),
              ),
            ),
        ],

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.xxl,
              DesignSpace.gutter,
              0,
            ),
            child: ActionButton(
              label: l10n.orderNow,
              icon: const Icon(CupertinoIcons.add),
              onPressed: () => _startOrder(context),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: LabelGroup(
            heading: l10n.ourServices,
            children: [
              for (final (id, name) in _ServiceRow.categories(context))
                LabelRow(
                  // The same four things read the same way here as in the
                  // order flow: the drawn glyph, not a photograph.
                  leading: CareGlyphIcon(
                    categoryGlyph(id),
                    color: context.colors.ink,
                    size: 26,
                  ),
                  title: name,
                  trailing: Icon(
                    CupertinoIcons.chevron_forward,
                    color: context.colors.inkTertiary,
                  ),
                  onTap: () => _startOrder(context),
                ),
            ],
          ),
        ),

        if (state.past.isNotEmpty)
          SliverToBoxAdapter(
            child: LabelGroup(
              heading: l10n.previousOrders,
              trailing: TintAction(
                label: l10n.viewAll,
                dense: true,
                onPressed: onViewAllOrders,
              ),
              children: [
                for (final order in state.past.take(3))
                  OrderListTile(
                    order: order,
                    onTap: () => _openOrder(context, order.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

abstract final class _ServiceRow {
  /// Mirrors the seeded catalog categories; the wizard loads the real list.
  static List<(String, String)> categories(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return [
      ('cat-clothes', isArabic ? 'ملابس' : 'Clothes'),
      ('cat-textiles', isArabic ? 'مفروشات' : 'Home textiles'),
      ('cat-carpets', isArabic ? 'سجاد' : 'Carpets'),
      ('cat-curtains', isArabic ? 'ستائر' : 'Curtains'),
    ];
  }
}
