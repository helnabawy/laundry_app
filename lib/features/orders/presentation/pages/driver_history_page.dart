import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/driver_task.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/driver_tasks_cubit.dart';
import '../widgets/status_pill.dart';

/// Completed pickups and deliveries: the day's stubs, kept.
class DriverHistoryPage extends StatelessWidget {
  const DriverHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LargeTitlePage(
      title: l10n.navHistory,
      onRefresh: () => context.read<DriverTasksCubit>().load(),
      slivers: [
        SliverToBoxAdapter(
          child: BlocBuilder<DriverTasksCubit, DriverTasksState>(
            builder: (context, state) {
              if (state.loading && state.completed.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignSpace.huge),
                  child: LoadingView(),
                );
              }
              if (state.completed.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignSpace.huge,
                  ),
                  child: EmptyView(message: l10n.noTasks),
                );
              }
              return LabelGroup(
                heading: l10n.completedTasks,
                children: [
                  for (final task in state.completed) _CompletedRow(task: task),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.task});

  final DriverTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);
    final order = task.order;
    return LabelRow(
      leading: CareGlyphIcon(
        task.type == TaskType.pickup ? CareGlyph.collect : CareGlyph.deliver,
        color: colors.ink,
        size: 26,
        bars: 1,
      ),
      title: l10n.orderNumber(order.number.toString()),
      subtitle: format.dayAndTime(task.slot.start),
      // The customer sees "Cancelled"; the driver's record is the failed stop.
      trailing: OrderStatusStamp(
        order.pickupFailedAndCancelled
            ? OrderStatus.pickupFailed
            : order.status,
        compact: true,
      ),
    );
  }
}
