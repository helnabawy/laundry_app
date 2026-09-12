import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/driver_task.dart';
import '../cubit/driver_tasks_cubit.dart';
import '../widgets/task_card.dart';

/// Plan §8.2 "مهام اليوم".
class DriverTasksPage extends StatefulWidget {
  const DriverTasksPage({super.key});

  @override
  State<DriverTasksPage> createState() => _DriverTasksPageState();
}

class _DriverTasksPageState extends State<DriverTasksPage> {
  var _showPickups = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverTasksCubit>().load(),
        child: BlocBuilder<DriverTasksCubit, DriverTasksState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.ink,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.todaysTasks,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${format.relativeDay(today)} ${today.day} ${format.month(today)}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  state.available ? l10n.available : l10n.unavailable,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const Spacer(),
                                Switch(
                                  value: state.available,
                                  onChanged: state.togglingAvailability
                                      ? null
                                      : (v) => context.read<DriverTasksCubit>().setAvailability(v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SegmentedTabs(
                              showPickups: _showPickups,
                              pickupCount: state.pickups.length,
                              deliveryCount: state.deliveries.length,
                              onChanged: (v) => setState(() => _showPickups = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.loading && state.tasks.isEmpty)
                  const SliverFillRemaining(child: LoadingView())
                else if (state.failure != null && state.tasks.isEmpty)
                  SliverFillRemaining(
                    child: ErrorView(
                      message: state.failure!.localized(l10n),
                      onRetry: () => context.read<DriverTasksCubit>().load(),
                    ),
                  )
                else
                  _TaskListSliver(
                    tasks: _showPickups ? state.pickups : state.deliveries,
                    emptyMessage: l10n.noTasks,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.showPickups,
    required this.pickupCount,
    required this.deliveryCount,
    required this.onChanged,
  });

  final bool showPickups;
  final int pickupCount;
  final int deliveryCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: l10n.pickupsTab(pickupCount),
              selected: showPickups,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.deliveriesTab(deliveryCount),
              selected: !showPickups,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.ink : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskListSliver extends StatelessWidget {
  const _TaskListSliver({required this.tasks, required this.emptyMessage});

  final List<DriverTask> tasks;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return SliverFillRemaining(child: EmptyView(message: emptyMessage));
    }
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final task = tasks[i];
          return TaskCard(
            task: task,
            onTap: () => context.push(
              task.type == TaskType.pickup
                  ? Routes.driverPickup(task.orderId)
                  : Routes.driverDelivery(task.orderId),
            ),
          );
        },
      ),
    );
  }
}
