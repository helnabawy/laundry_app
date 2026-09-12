import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/flow_header.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/task_detail_cubit.dart';
import '../utils/launchers.dart';
import '../widgets/failure_reason_sheet.dart';

/// Plan §8.2 "تأكيد التسليم" / §9 Stage 5.
class DeliveryDetailPage extends StatelessWidget {
  const DeliveryDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskDetailCubit>(param1: orderId),
      child: const _DeliveryDetailView(),
    );
  }
}

class _DeliveryDetailView extends StatefulWidget {
  const _DeliveryDetailView();

  @override
  State<_DeliveryDetailView> createState() => _DeliveryDetailViewState();
}

class _DeliveryDetailViewState extends State<_DeliveryDetailView> {
  var _cashCollected = false;
  var _hasProofPhoto = false;

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
          ).showSnackBar(SnackBar(content: Text(l10n.deliveryConfirmed)));
          context.pop(true);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.failure!.localized(l10n))),
        );
      },
      builder: (context, state) {
        final order = state.order;
        final invoice = order?.invoice;
        final needsCollection =
            invoice != null && invoice.paymentMethod == PaymentMethod.cashOnDelivery && !invoice.paid;

        return Scaffold(
          body: Column(
            children: [
              FlowHeader(
                title: order != null ? l10n.deliveryTitle(order.number.toString()) : '',
                subtitle: order != null
                    ? AppFormat.of(context).timeRange(
                        order.deliverySlot.start,
                        order.deliverySlot.end,
                      )
                    : null,
              ),
              Expanded(
                child: order == null || invoice == null
                    ? (state.loading
                          ? const LoadingView()
                          : ErrorView(
                              message: state.failure?.localized(l10n) ?? l10n.genericError,
                              onRetry: () => context.read<TaskDetailCubit>().load(),
                            ))
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.customerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${order.address.area}، ${order.address.city}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => launchTel(order.customerPhone),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                  ),
                                  icon: const Icon(Icons.call_outlined, size: 18),
                                  label: Text(l10n.call),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.deliveredItems,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                for (final item in invoice.items)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(item.name)),
                                        const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 6),
                                        Text('${item.quantity}'),
                                      ],
                                    ),
                                  ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    Text(
                                      l10n.total,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    const Spacer(),
                                    Text(
                                      AppFormat.of(context).money(invoice.total),
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (needsCollection)
                            _CollectCashCard(
                              amount: AppFormat.of(context).money(invoice.total),
                              collected: _cashCollected,
                              onToggle: (v) => setState(() => _cashCollected = v),
                            )
                          else
                            InfoBanner(
                              title: l10n.invoicePaidTitle,
                              message: l10n.noCollection,
                              tone: BannerTone.success,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.proofOfDelivery,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          _ProofPhotoBox(
                            hasPhoto: _hasProofPhoto,
                            onTap: () => setState(() => _hasProofPhoto = !_hasProofPhoto),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          bottomNavigationBar: order == null || order.status != OrderStatus.outForDelivery
              ? null
              : BottomActions(
                  children: [
                    PrimaryButton(
                      label: l10n.confirmDelivery,
                      tone: ButtonTone.accent,
                      loading: state.submitting,
                      onPressed: () {
                        if (needsCollection && !_cashCollected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.collectCashFirst)),
                          );
                          return;
                        }
                        context.read<TaskDetailCubit>().confirmDelivery(
                          cashCollected: _cashCollected,
                          hasProofPhoto: _hasProofPhoto,
                        );
                      },
                    ),
                    SecondaryButton(
                      label: l10n.deliveryFailed,
                      onPressed: state.submitting
                          ? null
                          : () async {
                              final result = await showFailureReasonSheet(
                                context,
                                title: l10n.deliveryFailed,
                              );
                              if (result != null && context.mounted) {
                                context.read<TaskDetailCubit>().reportDeliveryFailed(
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

class _CollectCashCard extends StatelessWidget {
  const _CollectCashCard({
    required this.amount,
    required this.collected,
    required this.onToggle,
  });

  final String amount;
  final bool collected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.collectAmountTitle(amount),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold),
                ),
                const SizedBox(height: 2),
                Text(l10n.collectAmountBody, style: const TextStyle(color: AppColors.gold)),
              ],
            ),
          ),
          FilterChip(
            selected: collected,
            onSelected: onToggle,
            avatar: collected ? const Icon(Icons.check, size: 16) : null,
            label: Text(l10n.cashCollected),
            selectedColor: AppColors.gold,
            labelStyle: TextStyle(color: collected ? Colors.white : AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class _ProofPhotoBox extends StatelessWidget {
  const _ProofPhotoBox({required this.hasPhoto, required this.onTap});

  final bool hasPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Icon(
                hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined,
                color: hasPhoto ? AppColors.success : AppColors.muted,
              ),
              const SizedBox(height: 8),
              Text(
                hasPhoto ? l10n.retakePhoto : l10n.takePhotoOptional,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
