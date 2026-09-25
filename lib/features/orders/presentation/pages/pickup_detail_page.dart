import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/task_detail_cubit.dart';
import '../utils/category_icons.dart';
import '../widgets/failure_reason_sheet.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/stop_contact.dart';

/// One pickup stop, printed on the routing tag.
class PickupDetailPage extends StatelessWidget {
  const PickupDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskDetailCubit>(param1: orderId),
      child: const _PickupDetailView(),
    );
  }
}

class _PickupDetailView extends StatelessWidget {
  const _PickupDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return BlocConsumer<TaskDetailCubit, TaskDetailState>(
      listenWhen: (prev, curr) =>
          (curr.done && !prev.done) ||
          (curr.failure != null && curr.failure != prev.failure),
      listener: (context, state) {
        if (state.done) {
          final reported = state.order?.pickupFailedAndCancelled ?? false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reported ? l10n.pickupFailedReported : l10n.pickupConfirmed,
              ),
            ),
          );
          context.pop(true);
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.failure!.localized(l10n))));
      },
      builder: (context, state) {
        final order = state.order;
        return DetailPage(
          title: order != null
              ? l10n.pickupTitle(order.number.toString())
              : l10n.navTasks,
          subtitle: order != null
              ? AppFormat.of(context)
                    .timeRange(order.pickupSlot.start, order.pickupSlot.end)
              : null,
          bottomBar: order == null || order.status != OrderStatus.driverAssigned
              ? null
              : ActionBar(
                  note: l10n.countAtLaundryBody,
                  children: [
                    ActionButton(
                      label: l10n.confirmPickup,
                      tone: ActionTone.field,
                      loading: state.submitting,
                      onPressed: () =>
                          context.read<TaskDetailCubit>().confirmPickup(),
                    ),
                    ActionButton(
                      label: l10n.pickupFailed,
                      tone: ActionTone.danger,
                      onPressed: state.submitting
                          ? null
                          : () async {
                              final result = await showFailureReasonSheet(
                                context,
                                title: l10n.pickupFailed,
                                requirePhoto: true,
                              );
                              if (result != null && context.mounted) {
                                context
                                    .read<TaskDetailCubit>()
                                    .reportPickupFailed(
                                      result.reason,
                                      result.note,
                                      hasPhoto: result.hasPhoto,
                                    );
                              }
                            },
                    ),
                  ],
                ),
          child: order == null
              ? (state.loading
                    ? const LoadingView()
                    : ErrorView(
                        message:
                            state.failure?.localized(l10n) ?? l10n.genericError,
                        retryLabel: l10n.retry,
                        onRetry: () => context.read<TaskDetailCubit>().load(),
                      ))
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    TagPanel(
                      padding: const EdgeInsets.fromLTRB(
                        DesignSpace.gutter,
                        DesignSpace.lg,
                        DesignSpace.gutter,
                        DesignSpace.lg,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CareGlyphIcon(
                            categoryGlyph(order.leadCategoryId),
                            color: colors.onTag,
                            size: 34,
                            dots: order.tier.isVip ? 2 : 1,
                          ),
                          const SizedBox(width: DesignSpace.lg),
                          Expanded(
                            child: SerialBlock(
                              serial: order.number.toString(),
                              size: 34,
                              color: colors.onTag,
                              caption:
                                  '${order.servicesLabel} · '
                                  '${order.tier.name}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignSpace.gutter,
                        DesignSpace.xl,
                        DesignSpace.gutter,
                        0,
                      ),
                      child: MapPlaceholder(address: order.address),
                    ),
                    const SizedBox(height: DesignSpace.xl),
                    StopContact(
                      name: order.customerName,
                      phone: order.customerPhone,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignSpace.gutter,
                        DesignSpace.xxl,
                        DesignSpace.gutter,
                        DesignSpace.huge,
                      ),
                      child: NoticeBlock(
                        title: l10n.countAtLaundryTitle,
                        message: l10n.countAtLaundryBody,
                        glyph: CareGlyphIcon(
                          CareGlyph.inspect,
                          color: colors.ink,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
