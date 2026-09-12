import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/driver_task.dart';
import '../cubit/driver_tasks_cubit.dart';
import '../widgets/status_pill.dart';

/// Driver "السجل" tab: completed pickups/deliveries.
class DriverHistoryPage extends StatelessWidget {
  const DriverHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.completedTasks)),
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverTasksCubit>().load(),
        child: BlocBuilder<DriverTasksCubit, DriverTasksState>(
          builder: (context, state) {
            if (state.loading && state.completed.isEmpty) return const LoadingView();
            if (state.completed.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .6,
                    child: EmptyView(message: l10n.noTasks),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.completed.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _CompletedRow(task: state.completed[i]),
            );
          },
        ),
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.task});

  final DriverTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final order = task.order;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(
            task.type == TaskType.pickup
                ? Icons.inventory_2_outlined
                : Icons.local_shipping_outlined,
            color: AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.orderNumber(order.number.toString()),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  format.dayAndTime(task.slot.start),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          OrderStatusPill(order.status),
        ],
      ),
    );
  }
}
