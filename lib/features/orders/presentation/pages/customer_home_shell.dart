import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../auth/presentation/widgets/account_page.dart';
import '../cubit/orders_cubit.dart';
import 'home_page.dart';
import 'my_orders_page.dart';

/// Tab shell for the customer role. All three tabs share one [OrdersCubit]
/// loaded once here.
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

  /// The order list is the subject of two of the three tabs, and an order can
  /// be created or advanced while this shell is alive. Re-reading it on tab
  /// change is cheap and keeps the hero from claiming nothing is in custody
  /// when something is.
  void _select(int index) {
    setState(() => _index = index);
    if (index != 2) unawaited(context.read<OrdersCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final pages = [
      HomePage(onViewAllOrders: _goToOrders),
      const MyOrdersPage(),
      const AccountPage(),
    ];

    return Scaffold(
      backgroundColor: colors.tape,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: TapeTabBar(
        currentIndex: _index,
        onSelected: _select,
        tabs: [
          TapeTab(
            icon: CupertinoIcons.house,
            activeIcon: CupertinoIcons.house_fill,
            label: l10n.navHome,
          ),
          TapeTab(
            icon: CupertinoIcons.doc_text,
            activeIcon: CupertinoIcons.doc_text_fill,
            label: l10n.navOrders,
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
