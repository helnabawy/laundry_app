import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../cubit/order_tracking_cubit.dart';
import '../widgets/invoice_summary_card.dart';
import '../widgets/hero_custody.dart';
import '../widgets/order_timeline.dart';

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

    return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
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
          subtitle: order.servicesLabel,
          child: RefreshIndicator(
            color: colors.ink,
            backgroundColor: colors.tape,
            onRefresh: () => context.read<OrderTrackingCubit>().load(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HeroCustody(order: order),
                if (order.driverName case final driver?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSpace.gutter,
                      DesignSpace.xl,
                      DesignSpace.gutter,
                      0,
                    ),
                    child: Text(
                      l10n.driverName(driver),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.inkSecondary),
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
                if (order.invoice case final invoice?)
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
