import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../auth/presentation/widgets/account_page.dart';
import '../cubit/orders_cubit.dart';
import 'home_page.dart';
import 'my_orders_page.dart';

/// Bottom-nav shell for the customer role (plan §8.1: الرئيسية / طلباتي /
/// حسابي). All 3 tabs share one [OrdersCubit] loaded once here.
class CustomerHomeShell extends StatelessWidget {
  const CustomerHomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersCubit>()..load(),
      child: const _CustomerHomeView(),
    );
  }
}

class _CustomerHomeView extends StatefulWidget {
  const _CustomerHomeView();

  @override
  State<_CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<_CustomerHomeView> {
  var _index = 0;

  void _goToOrders() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      HomePage(onViewAllOrders: _goToOrders),
      const MyOrdersPage(),
      const AccountPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.navHome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l10n.navOrders),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.navAccount),
        ],
      ),
    );
  }
}
