import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/laundry_order.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_list_tile.dart';

/// Plan §8.1 "طلباتي": active / past tabs.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrders),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.activeOrders), Tab(text: l10n.pastOrders)],
        ),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state.loading && state.orders.isEmpty) return const LoadingView();
          if (state.failure != null && state.orders.isEmpty) {
            return ErrorView(
              message: state.failure!.localized(l10n),
              onRetry: () => context.read<OrdersCubit>().load(),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: state.active,
                emptyMessage: l10n.noActiveOrders,
                onRefresh: () => context.read<OrdersCubit>().load(),
              ),
              _OrderList(
                orders: state.past,
                emptyMessage: l10n.noPastOrders,
                onRefresh: () => context.read<OrdersCubit>().load(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final List<LaundryOrder> orders;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * .5,
              child: EmptyView(message: emptyMessage),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => OrderListTile(
          order: orders[i],
          onTap: () => context.push(Routes.orderDetail(orders[i].id)),
        ),
      ),
    );
  }
}
