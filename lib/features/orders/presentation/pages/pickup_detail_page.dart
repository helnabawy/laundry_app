import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/phone_format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/flow_header.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/task_detail_cubit.dart';
import '../utils/launchers.dart';
import '../widgets/failure_reason_sheet.dart';
import '../widgets/map_placeholder.dart';

/// Plan §8.2 "تفاصيل الاستلام" / §9 Stage 3.
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
    return BlocConsumer<TaskDetailCubit, TaskDetailState>(
      listenWhen: (prev, curr) =>
          (curr.done && !prev.done) || (curr.failure != null && curr.failure != prev.failure),
      listener: (context, state) {
        if (state.done) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.pickupConfirmed)));
          context.pop(true);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.failure!.localized(l10n))),
        );
      },
      builder: (context, state) {
        final order = state.order;
        return Scaffold(
          body: Column(
            children: [
              FlowHeader(
                title: order != null ? l10n.pickupTitle(order.number.toString()) : '',
                subtitle: order != null
                    ? AppFormat.of(context).timeRange(
                        order.pickupSlot.start,
                        order.pickupSlot.end,
                      )
                    : null,
              ),
              Expanded(
                child: order == null
                    ? (state.loading
                          ? const LoadingView()
                          : ErrorView(
                              message: state.failure?.localized(l10n) ?? l10n.genericError,
                              onRetry: () => context.read<TaskDetailCubit>().load(),
                            ))
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          MapPlaceholder(address: order.address),
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: AppColors.tealSoft,
                                      child: Icon(Icons.person, color: AppColors.tealDark),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.customerName,
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            formatUaePhone(order.customerPhone),
                                            style: const TextStyle(color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => launchTel(order.customerPhone),
                                        icon: const Icon(Icons.call_outlined, size: 18),
                                        label: Text(l10n.call),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => launchSms(order.customerPhone),
                                        icon: const Icon(Icons.sms_outlined, size: 18),
                                        label: Text(l10n.message),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order.address.area}، ${order.address.city}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.buildingApartment(
                                    order.address.building,
                                    order.address.apartment,
                                  ),
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${order.category.name} · ${order.subService.name} · ${order.tier.name}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          InfoBanner(
                            title: l10n.countAtLaundryTitle,
                            message: l10n.countAtLaundryBody,
                          ),
                        ],
                      ),
              ),
            ],
          ),
          bottomNavigationBar: order == null || order.status != OrderStatus.driverAssigned
              ? null
              : BottomActions(
                  children: [
                    PrimaryButton(
                      label: l10n.confirmPickup,
                      tone: ButtonTone.accent,
                      loading: state.submitting,
                      onPressed: () => context.read<TaskDetailCubit>().confirmPickup(),
                    ),
                    SecondaryButton(
                      label: l10n.pickupFailed,
                      onPressed: state.submitting
                          ? null
                          : () async {
                              final result = await showFailureReasonSheet(
                                context,
                                title: l10n.pickupFailed,
                              );
                              if (result != null && context.mounted) {
                                context.read<TaskDetailCubit>().reportPickupFailed(
                                  result.reason,
                                  result.note,
                                );
                              }
                            },
                    ),
                  ],
                ),
        );
      },
    );
  }
}
