import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/driver_task.dart';
import '../cubit/driver_tasks_cubit.dart';
import '../widgets/task_card.dart';

/// The driver's day, printed on the routing tag.
///
/// Hi-vis ground, ink type, one stop per row. Colour is committed here on
/// purpose: this screen is read in direct sun, at arm's length.
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
    final colors = context.colors;
    final format = AppFormat.of(context);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: colors.tape,
      body: BlocBuilder<DriverTasksCubit, DriverTasksState>(
        builder: (context, state) {
          final tasks = _showPickups ? state.pickups : state.deliveries;
          return RefreshIndicator(
            color: colors.ink,
            backgroundColor: colors.tape,
            onRefresh: () => context.read<DriverTasksCubit>().load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: TagHeader(
                    title: l10n.todaysTasks,
                    shift:
                        '${format.relativeDay(today)} ${today.day} ${format.month(today)}',
                    count: '${state.pickups.length + state.deliveries.length}',
                    countLabel: l10n.navTasks,
                  ),
                ),
                SliverToBoxAdapter(
                  child: TagPanel(
                    ruledTop: true,
                    padding: const EdgeInsets.fromLTRB(
                      DesignSpace.gutter,
                      DesignSpace.md,
                      DesignSpace.gutter,
                      DesignSpace.md,
                    ),
                    child: _AvailabilityRow(state: state),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSpace.gutter,
                      DesignSpace.lg,
                      DesignSpace.gutter,
                      DesignSpace.lg,
                    ),
                    child: _TagSegmented(
                      labels: [
                        l10n.pickupsTab(state.pickups.length),
                        l10n.deliveriesTab(state.deliveries.length),
                      ],
                      index: _showPickups ? 0 : 1,
                      onChanged: (i) => setState(() => _showPickups = i == 0),
                    ),
                  ),
                ),
                if (state.loading && state.tasks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingView(),
                  )
                else if (state.failure != null && state.tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      message: state.failure!.localized(l10n),
                      retryLabel: l10n.retry,
                      onRetry: () => context.read<DriverTasksCubit>().load(),
                    ),
                  )
                else if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      message: l10n.noTasks,
                      glyph: _showPickups
                          ? CareGlyph.collect
                          : CareGlyph.deliver,
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return TaskCard(
                        task: task,
                        // A stop can be confirmed or failed while it is open,
                        // so the day is re-read on the way back rather than
                        // leaving a completed stop sitting in the list.
                        onTap: () async {
                          final cubit = context.read<DriverTasksCubit>();
                          await context.push<bool>(
                            task.type == TaskType.pickup
                                ? Routes.driverPickup(task.orderId)
                                : Routes.driverDelivery(task.orderId),
                          );
                          await cubit.load();
                        },
                      );
                    },
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignSpace.huge),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.state});

  final DriverTasksState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Row(
      children: [
        CareGlyphIcon(
          CareGlyph.custody,
          color: colors.onTag,
          size: 22,
          filled: state.available,
          crossed: !state.available,
          crossColor: colors.onTag,
        ),
        const SizedBox(width: DesignSpace.md),
        Expanded(
          child: Text(
            (state.available ? l10n.available : l10n.unavailable).toUpperCase(),
            style: DesignTypography.stamp(colors.onTag, size: 13),
          ),
        ),
        // The platform control, tinted from the world. A bespoke switch is
        // the off-spec tell an iPhone user reads as untrustworthy.
        CupertinoSwitch(
          value: state.available,
          activeTrackColor: colors.onTag,
          inactiveTrackColor: colors.onTag.withValues(alpha: .30),
          thumbColor: colors.tag,
          onChanged: state.togglingAvailability
              ? null
              : (v) => context.read<DriverTasksCubit>().setAvailability(v),
        ),
      ],
    );
  }
}

/// Two fields on the tag; the chosen one inverts to ink.
class _TagSegmented extends StatelessWidget {
  const _TagSegmented({
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
                    height: 44,
                    alignment: Alignment.center,
                    color: i == index ? colors.ink : const Color(0x00000000),
                    child: Text(
                      labels[i].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTypography.stamp(
                        i == index ? colors.onInk : colors.inkSecondary,
                        size: 12,
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
