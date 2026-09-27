import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/task_detail_cubit.dart';
import '../widgets/failure_reason_sheet.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/proof_photo_field.dart';
import '../widgets/stop_contact.dart';
import '../widgets/vip_mark.dart';

/// One delivery stop: hand the items over, collect what is owed, confirm.
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
  String? _proofPhotoPath;

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
          final reported = state.order?.status == OrderStatus.deliveryFailed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reported ? l10n.reportSubmitted : l10n.deliveryConfirmed,
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
        final invoice = order?.invoice;
        final needsCollection =
            invoice != null &&
            invoice.paymentMethod == PaymentMethod.cashOnDelivery &&
            !invoice.paid;
        final format = AppFormat.of(context);

        return DetailPage(
          title: order != null
              ? l10n.deliveryTitle(order.number.toString())
              : l10n.navTasks,
          subtitle: order != null
              ? format.timeRange(
                  order.deliverySlot.start,
                  order.deliverySlot.end,
                )
              : null,
          bottomBar: order == null || order.status != OrderStatus.outForDelivery
              ? null
              : ActionBar(
                  note: needsCollection && !_cashCollected
                      ? l10n.collectCashFirst
                      : null,
                  children: [
                    ActionButton(
                      label: l10n.confirmDelivery,
                      tone: ActionTone.field,
                      loading: state.submitting,
                      onPressed: needsCollection && !_cashCollected
                          ? null
                          : () =>
                                context.read<TaskDetailCubit>().confirmDelivery(
                                  cashCollected: _cashCollected,
                                  proofPhotoPath: _proofPhotoPath,
                                ),
                    ),
                    ActionButton(
                      label: l10n.deliveryFailed,
                      tone: ActionTone.danger,
                      onPressed: state.submitting
                          ? null
                          : () async {
                              final result = await showFailureReasonSheet(
                                context,
                                title: l10n.deliveryFailed,
                              );
                              if (result != null && context.mounted) {
                                context
                                    .read<TaskDetailCubit>()
                                    .reportDeliveryFailed(
                                      result.reason,
                                      result.note,
                                    );
                              }
                            },
                    ),
                  ],
                ),
          child: order == null || invoice == null
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SerialBlock(
                              serial: order.number.toString(),
                              size: 34,
                              color: colors.onTag,
                              caption:
                                  '${order.customerName} · '
                                  '${order.address.area}${l10n.listSeparator}'
                                  '${order.address.city}',
                            ),
                          ),
                          if (order.tier.isVip) ...[
                            const SizedBox(width: DesignSpace.md),
                            VipMark(tier: order.tier, compact: false),
                          ],
                        ],
                      ),
                    ),
                    if (order.tier.isVip) const TwinStitch(),
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

                    LabelGroup(
                      heading: l10n.deliveredItems,
                      children: [
                        for (final item in invoice.items)
                          LabelRow(title: item.name, value: '${item.quantity}'),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignSpace.gutter,
                        DesignSpace.xl,
                        DesignSpace.gutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FieldLine(
                            label: l10n.total,
                            value: format.money(invoice.total),
                            emphasised: true,
                          ),
                        ],
                      ),
                    ),
                    // Payment is always settled one of two ways: online (already
                    // charged) or in cash at the door. The customer's choice
                    // decides which applies; the driver sees it, never guesses.
                    LabelGroup(
                      heading: l10n.paymentMethod,
                      children: [
                        LabelRow(
                          title: l10n.card,
                          selected: invoice.paymentMethod == PaymentMethod.card,
                          trailing: invoice.paymentMethod == PaymentMethod.card
                              ? const Icon(CupertinoIcons.checkmark_alt)
                              : null,
                        ),
                        LabelRow(
                          title: l10n.cashOnDelivery,
                          selected:
                              invoice.paymentMethod ==
                              PaymentMethod.cashOnDelivery,
                          trailing:
                              invoice.paymentMethod ==
                                  PaymentMethod.cashOnDelivery
                              ? const Icon(CupertinoIcons.checkmark_alt)
                              : null,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignSpace.gutter,
                        DesignSpace.lg,
                        DesignSpace.gutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (needsCollection)
                            _CollectCash(
                              amount: format.money(invoice.total),
                              collected: _cashCollected,
                              onToggle: (v) =>
                                  setState(() => _cashCollected = v),
                            )
                          else
                            NoticeBlock(
                              title: l10n.invoicePaidTitle,
                              message: l10n.noCollection,
                              tone: NoticeTone.done,
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSpace.gutter,
                      ),
                      child: StampHeading(l10n.proofOfDelivery),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignSpace.gutter,
                        0,
                        DesignSpace.gutter,
                        DesignSpace.huge,
                      ),
                      child: ProofPhotoField(
                        photoPath: _proofPhotoPath,
                        prompt: l10n.takePhotoOptional,
                        onChanged: (path) =>
                            setState(() => _proofPhotoPath = path),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Cash owed is the one thing on this screen that can go wrong after the fact,
/// so it holds the confirm action hostage until the driver marks it collected.
class _CollectCash extends StatelessWidget {
  const _CollectCash({
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
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignSpace.lg),
      decoration: BoxDecoration(
        color: collected ? colors.tape : colors.tag,
        border: Border.all(
          color: collected ? colors.rule : colors.onTag,
          width: DesignRule.medium,
        ),
        borderRadius: BorderRadius.circular(DesignRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.collectAmountTitle(amount).toUpperCase(),
            style: DesignTypography.stamp(
              collected ? colors.ink : colors.onTag,
              size: 14,
            ),
          ),
          const SizedBox(height: DesignSpace.xs),
          Text(
            l10n.collectAmountBody,
            style: text.bodySmall?.copyWith(
              color: collected
                  ? colors.inkSecondary
                  : colors.onTag.withValues(alpha: .8),
            ),
          ),
          const SizedBox(height: DesignSpace.lg),
          ActionButton(
            label: l10n.cashCollected,
            tone: collected ? ActionTone.secondary : ActionTone.primary,
            icon: collected ? const Icon(CupertinoIcons.checkmark_alt) : null,
            onPressed: () => onToggle(!collected),
          ),
        ],
      ),
    );
  }
}
