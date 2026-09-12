import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../auth/presentation/widgets/account_page.dart';
import '../cubit/driver_tasks_cubit.dart';
import 'driver_history_page.dart';
import 'driver_tasks_page.dart';

/// Bottom-nav shell for the driver role (plan §8.2 nav: المهام / السجل /
/// حسابي). Tasks and history share one [DriverTasksCubit] loaded here.
class DriverHomeShell extends StatelessWidget {
  const DriverHomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DriverTasksCubit>()..load(),
      child: const _DriverHomeView(),
    );
  }
}

class _DriverHomeView extends StatefulWidget {
  const _DriverHomeView();

  @override
  State<_DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<_DriverHomeView> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const pages = [DriverTasksPage(), DriverHistoryPage(), AccountPage()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.task_outlined), selectedIcon: const Icon(Icons.task), label: l10n.navTasks),
          NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history), label: l10n.navHistory),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.navAccount),
        ],
      ),
    );
  }
}
