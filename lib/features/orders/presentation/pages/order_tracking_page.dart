import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../laundries/presentation/cubit/laundry_cubit.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/order_tracking_cubit.dart';
import '../widgets/invoice_summary_card.dart';
import '../widgets/hero_custody.dart';
import '../widgets/order_rating_panel.dart';
import '../widgets/order_timeline.dart';
import '../widgets/pickup_failed_notice.dart';

/// Where the order stands, read off the strip and then down the record.
class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderTrackingCubit>(param1: orderId),
      child: const _OrderTrackingView(),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  const _OrderTrackingView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return BlocConsumer<OrderTrackingCubit, OrderTrackingState>(
      // A failed refresh or rating keeps the order on screen, so it is
      // reported here rather than replacing the page with an error.
      listenWhen: (prev, curr) =>
          curr.order != null &&
          curr.failure != null &&
          curr.failure != prev.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.failure!.localized(l10n))));
      },
      builder: (context, state) {
        final order = state.order;
        if (order == null) {
          return DetailPage(
            title: l10n.trackOrder,
            child: state.loading
                ? const LoadingView()
                : ErrorView(
                    message:
                        state.failure?.localized(l10n) ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<OrderTrackingCubit>().load(),
                  ),
          );
        }

        return DetailPage(
          title: l10n.orderNumber(order.number.toString()),
          subtitle: [
            order.servicesLabel,
            order.laundryName,
          ].whereType<String>().join(' · '),
          // Plan §9 Stage 5: any finished order can be repeated in one tap,
          // with the wizard filled from it. A cancelled pickup reads as
          // rebooking, since that is what the customer is doing.
          bottomBar: order.status.isPast
              ? ActionBar(
                  children: [
                    ActionButton(
                      label: order.pickupFailedAndCancelled
                          ? l10n.reschedulePickup
                          : l10n.reorder,
                      icon: const Icon(CupertinoIcons.arrow_clockwise),
                      // Rating is this page's first ask once delivered.
                      tone: order.canRate
                          ? ActionTone.secondary
                          : ActionTone.primary,
                      onPressed: () async {
                        await sl<LaundryCubit>().switchTo(order.laundryId);
                        if (context.mounted) {
                          await context.push(Routes.orderNew, extra: order);
                        }
                      },
                    ),
                  ],
                )
              : null,
          child: RefreshIndicator(
            color: colors.ink,
            backgroundColor: colors.tape,
            onRefresh: () => context.read<OrderTrackingCubit>().load(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HeroCustody(order: order),
                if (order.status == OrderStatus.delivered)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSpace.gutter,
                      DesignSpace.aboveHeading,
                      DesignSpace.gutter,
                      0,
                    ),
                    child: OrderRatingPanel(
                      rating: order.rating,
                      submitting: state.rating,
                      onSubmit: (stars, comment) => context
                          .read<OrderTrackingCubit>()
                          .rate(stars, comment: comment),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSpace.gutter,
                    DesignSpace.aboveHeading,
                    DesignSpace.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StampHeading(
                        l10n.trackOrder,
                        padding: const EdgeInsets.only(
                          bottom: DesignSpace.belowHeading,
                        ),
                      ),
                      OrderTimeline(order: order),
                    ],
                  ),
                ),
                // Sorting found stains or damage: the customer hears about it
                // here before processing, which waits on their invoice.
                if (order.invoice case final invoice?
                    when invoice.hasConditions && invoice.paymentMethod == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSpace.gutter,
                      0,
                      DesignSpace.gutter,
                      DesignSpace.md,
                    ),
                    child: NoticeBlock(
                      tone: NoticeTone.caution,
                      glyph: const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                      ),
                      title: l10n.conditionsFoundTitle,
                      message: l10n.conditionsNoticeBody,
                    ),
                  ),
                if (order.pickupFailedAndCancelled)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSpace.gutter,
                    ),
                    // Rebooking is the page's prefilled "Reorder" action.
                    child: PickupFailedNotice(order: order),
                  )
                else if (order.invoice case final invoice?)
                  InvoiceSummaryCard(
                    invoice: invoice,
                    // Paying happens on the invoice, so this page re-reads
                    // the order rather than keeping the pre-payment summary.
                    onTap: () async {
                      final cubit = context.read<OrderTrackingCubit>();
                      await context.push(Routes.orderInvoice(order.id));
                      await cubit.load();
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSpace.gutter,
                    ),
                    child: NoticeBlock(
                      title: l10n.invoiceAfterInspection,
                      message: l10n.invoiceNotReady,
                    ),
                  ),
                const SizedBox(height: DesignSpace.huge),
              ],
            ),
          ),
        );
      },
    );
  }
}
