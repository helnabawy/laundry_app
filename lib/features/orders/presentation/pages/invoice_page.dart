import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/flow_header.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/labeled_rows.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/invoice.dart';
import '../cubit/order_tracking_cubit.dart';
import '../widgets/invoice_summary_card.dart';

/// Plan §8.1 "الفاتورة" / step 4.4 "يختار الدفع بالبطاقة أو الدفع عند
/// التسليم".
class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderTrackingCubit>(param1: orderId),
      child: const _InvoiceView(),
    );
  }
}

class _InvoiceView extends StatefulWidget {
  const _InvoiceView();

  @override
  State<_InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<_InvoiceView> {
  PaymentMethod _method = PaymentMethod.card;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<OrderTrackingCubit, OrderTrackingState>(
      listenWhen: (prev, curr) => curr.failure != null && curr.failure != prev.failure,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.failure!.localized(l10n))),
      ),
      builder: (context, state) {
        final order = state.order;
        final invoice = order?.invoice;
        return Scaffold(
          body: Column(
            children: [
              FlowHeader(
                title: l10n.invoiceTitle,
                subtitle: invoice?.id.toUpperCase(),
              ),
              Expanded(
                child: order == null || invoice == null
                    ? (state.loading
                          ? const LoadingView()
                          : ErrorView(
                              message: state.failure?.localized(l10n) ?? l10n.genericError,
                              onRetry: () => context.read<OrderTrackingCubit>().load(),
                            ))
                    : _InvoiceBody(invoice: invoice, method: _method, onMethod: (m) => setState(() => _method = m)),
              ),
            ],
          ),
          bottomNavigationBar: invoice == null || invoice.paymentMethod != null
              ? null
              : BottomActions(
                  children: [
                    PrimaryButton(
                      label: l10n.payAmount(AppFormat.of(context).money(invoice.total)),
                      tone: ButtonTone.accent,
                      loading: state.paying,
                      onPressed: () =>
                          context.read<OrderTrackingCubit>().choosePaymentMethod(_method),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.invoice, required this.method, required this.onMethod});

  final Invoice invoice;
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethod;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppFormat.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.itemsDetails,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final item in invoice.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(format.money(item.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const Divider(height: 28),
              KeyValueRow(label: l10n.subtotal, value: format.money(invoice.total)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.total,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Text(
                    format.money(invoice.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (invoice.note != null) ...[
          const SizedBox(height: 16),
          InfoBanner(title: l10n.laundryNote, message: invoice.note, tone: BannerTone.warning),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.paymentMethod,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (invoice.paymentMethod != null)
          InvoiceSummaryCard(invoice: invoice, onTap: () {})
        else ...[
          _PaymentOption(
            label: l10n.card,
            icon: Icons.credit_card,
            selected: method == PaymentMethod.card,
            onTap: () => onMethod(PaymentMethod.card),
          ),
          const SizedBox(height: 10),
          _PaymentOption(
            label: l10n.cashOnDelivery,
            icon: Icons.payments_outlined,
            selected: method == PaymentMethod.cashOnDelivery,
            onTap: () => onMethod(PaymentMethod.cashOnDelivery),
          ),
        ],
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          SelectionIndicator(selected: selected),
        ],
      ),
    );
  }
}
