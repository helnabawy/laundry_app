import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../auth/presentation/widgets/account_page.dart';
import '../cubit/driver_tasks_cubit.dart';
import 'driver_history_page.dart';
import 'driver_tasks_page.dart';

/// Tab shell for the driver role. Tasks and history share one
/// [DriverTasksCubit] loaded here.
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

  /// Tasks and history share one cubit and both can change while the shell is
  /// alive, so a tab change re-reads them.
  void _select(int index) {
    setState(() => _index = index);
    if (index != 2) unawaited(context.read<DriverTasksCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    const pages = [DriverTasksPage(), DriverHistoryPage(), AccountPage()];

    return Scaffold(
      backgroundColor: colors.tape,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: TapeTabBar(
        currentIndex: _index,
        onSelected: _select,
        tabs: [
          TapeTab(
            icon: CupertinoIcons.square_list,
            activeIcon: CupertinoIcons.square_list_fill,
            label: l10n.navTasks,
          ),
          TapeTab(
            icon: CupertinoIcons.clock,
            activeIcon: CupertinoIcons.clock_fill,
            label: l10n.navHistory,
          ),
          TapeTab(
            icon: CupertinoIcons.person,
            activeIcon: CupertinoIcons.person_fill,
            label: l10n.navAccount,
          ),
        ],
      ),
    );
  }
}
