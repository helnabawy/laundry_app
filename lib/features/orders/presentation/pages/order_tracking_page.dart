import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/order_tracking_cubit.dart';
import '../utils/order_status_x.dart';
import '../widgets/invoice_summary_card.dart';
import '../widgets/order_timeline.dart';

/// Plan §8.1 "تتبع الطلب".
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
    return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
      builder: (context, state) {
        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(),
            body: state.loading
                ? const LoadingView()
                : ErrorView(
                    message: state.failure?.localized(l10n) ?? l10n.genericError,
                    onRetry: () => context.read<OrderTrackingCubit>().load(),
                  ),
          );
        }
        final format = AppFormat.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.orderNumber(order.number.toString())),
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<OrderTrackingCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: order.status.tone.solid,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.label(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.status.isActive
                            ? l10n.expectedDelivery(
                                format.slotRelative(
                                  order.deliverySlot.start,
                                  order.deliverySlot.end,
                                ),
                              )
                            : format.slotWithDate(
                                order.deliverySlot.start,
                                order.deliverySlot.end,
                              ),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OrderTimeline(order: order),
                if (order.invoice != null) ...[
                  const SizedBox(height: 4),
                  InvoiceSummaryCard(
                    invoice: order.invoice!,
                    onTap: () => context.push(Routes.orderInvoice(order.id)),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.invoiceNotReady,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
