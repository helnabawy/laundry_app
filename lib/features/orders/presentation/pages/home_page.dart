import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../cubit/orders_cubit.dart';
import '../utils/category_icons.dart';
import '../widgets/order_list_tile.dart';

/// Plan §8.1 "الرئيسية".
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onViewAllOrders});

  final VoidCallback onViewAllOrders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ordersState = context.watch<OrdersCubit>().state;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<OrdersCubit>().load(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(hasPickupToday: _hasPickupToday(ordersState)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ordersState.loading && ordersState.orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: LoadingView(),
                    )
                  else ...[
                    if (ordersState.current != null) ...[
                      Text(
                        l10n.currentOrder,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OrderListTile(
                        order: ordersState.current!,
                        detailed: true,
                        onTap: () => context.push(
                          Routes.orderDetail(ordersState.current!.id),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (ordersState.past.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.previousOrders,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton(
                            onPressed: onViewAllOrders,
                            child: Text(l10n.viewAll),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final order in ordersState.past.take(2)) ...[
                        OrderListTile(
                          order: order,
                          onTap: () => context.push(Routes.orderDetail(order.id)),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 20),
                    ],
                    Text(
                      l10n.ourServices,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _ServicesGrid(onTap: () => context.push(Routes.orderNew)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool? _hasPickupToday(OrdersState state) {
    final current = state.current;
    if (current == null) return null;
    if (current.status.name != 'driverAssigned') return false;
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.isSameDay(current.pickupSlot.start, today);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.hasPickupToday});

  /// null = no active order at all.
  final bool? hasPickupToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<SessionCubit>().state;
    final name = user is SessionAuthenticated ? user.user.firstName : '';
    final isMorning = DateTime.now().hour < 17;

    return Container(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMorning
                              ? l10n.greetingMorning(name)
                              : l10n.greetingEvening(name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          hasPickupToday == true ? l10n.pickupToday : l10n.noPickupToday,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push(Routes.orderNew),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.orderNow,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n.orderNowSubtitle,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.onTap});

  final VoidCallback onTap;

  static const _categories = [
    ('cat-clothes', {'ar': 'ملابس', 'en': 'Clothes'}),
    ('cat-textiles', {'ar': 'مفروشات', 'en': 'Home Textiles'}),
    ('cat-carpets', {'ar': 'سجاد', 'en': 'Carpets'}),
    ('cat-curtains', {'ar': 'ستائر', 'en': 'Curtains'}),
  ];

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: .8,
      children: [
        for (final (id, name) in _categories)
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(categoryIcon(id), color: AppColors.ink),
                    const SizedBox(height: 8),
                    Text(
                      name[languageCode] ?? name['en']!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
