import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_list_tile.dart';

/// The customer's own record: active and past orders.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final orders = _tab == 0 ? state.active : state.past;
        final empty = _tab == 0 ? l10n.noActiveOrders : l10n.noPastOrders;

        return LargeTitlePage(
          title: l10n.myOrders,
          onRefresh: () => context.read<OrdersCubit>().load(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSpace.gutter,
                  DesignSpace.sm,
                  DesignSpace.gutter,
                  DesignSpace.lg,
                ),
                child: _Segmented(
                  labels: [
                    '${l10n.activeOrders} (${state.active.length})',
                    '${l10n.pastOrders} (${state.past.length})',
                  ],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
            ),
            if (state.loading && state.orders.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingView(),
              )
            else if (state.failure != null && state.orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: state.failure!.localized(l10n),
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<OrdersCubit>().load(),
                ),
              )
            else if (orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(message: empty),
              )
            else
              SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: colors.tape),
                  child: LabelGroup(
                    children: [
                      for (final order in orders)
                        OrderListTile(
                          order: order,
                          onTap: () async {
                            final cubit = context.read<OrdersCubit>();
                            await context.push(Routes.orderDetail(order.id));
                            await cubit.load();
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Two fields on one strip; the chosen one inverts.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.ruleStrong),
        borderRadius: BorderRadius.circular(DesignRadius.slot),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: DesignMotion.quick,
                    height: 40,
                    alignment: Alignment.center,
                    color: i == index ? colors.ink : const Color(0x00000000),
                    child: Text(
                      labels[i].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTypography.stamp(
                        i == index ? colors.onInk : colors.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
