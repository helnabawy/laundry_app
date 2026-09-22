import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/laundry_order.dart';
import '../cubit/order_tracking_cubit.dart';
import '../utils/treatment_symbols.dart';
import '../widgets/invoice_summary_card.dart';

/// The label's reverse: what was counted, what it costs, and how it is paid.
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
      listenWhen: (prev, curr) =>
          curr.failure != null && curr.failure != prev.failure,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.failure!.localized(l10n)))),
      builder: (context, state) {
        final order = state.order;
        final invoice = order?.invoice;

        return DetailPage(
          title: l10n.invoiceTitle,
          subtitle: invoice?.id.toUpperCase(),
          bottomBar: invoice == null || invoice.paymentMethod != null
              ? null
              : ActionBar(
                  children: [
                    ActionButton(
                      label: l10n.payAmount(
                        AppFormat.of(context).money(invoice.total),
                      ),
                      loading: state.paying,
                      onPressed: () => context
                          .read<OrderTrackingCubit>()
                          .choosePaymentMethod(_method),
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
                        onRetry: () =>
                            context.read<OrderTrackingCubit>().load(),
                      ))
              : _InvoiceBody(
                  order: order,
                  invoice: invoice,
                  method: _method,
                  onMethod: (m) => setState(() => _method = m),
                ),
        );
      },
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.order,
    required this.invoice,
    required this.method,
    required this.onMethod,
  });

  final LaundryOrder order;
  final Invoice invoice;
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethod;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // The one honest place for the standardised care symbols: what the
        // facility actually did, derived from the service bought for each
        // category. A line with no mapped service shows no symbols rather
        // than borrowing another line's.
        for (final line in order.lines)
          if (treatmentSymbols(line.subService.id) case final symbols
              when symbols.isNotEmpty)
            TapeBand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.label.toUpperCase(),
                    style: DesignTypography.stamp(colors.inkSecondary),
                  ),
                  const SizedBox(height: DesignSpace.md),
                  Row(
                    children: [
                      for (final symbol in symbols)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: DesignSpace.lg,
                          ),
                          child: CareSymbolIcon(
                            symbol,
                            color: colors.ink,
                            size: 26,
                            semanticLabel: careSymbolLabel(symbol),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(l10n.itemsDetails),
        ),
        LabelGroup(
          children: [
            for (final item in invoice.items)
              LabelRow(
                title: item.name,
                subtitle: '${item.quantity} × ${format.money(item.unitPrice)}',
                value: format.money(item.total),
              ),
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
                label: l10n.subtotal,
                value: format.money(invoice.total),
              ),
              const StitchRule.dashed(),
              FieldLine(
                label: l10n.total,
                value: format.money(invoice.total),
                emphasised: true,
              ),
            ],
          ),
        ),

        if (invoice.note case final note?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.xl,
              DesignSpace.gutter,
              0,
            ),
            child: NoticeBlock(title: l10n.laundryNote, message: note),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(l10n.paymentMethod),
        ),
        if (invoice.paymentMethod != null)
          InvoiceSummaryCard(invoice: invoice, onTap: () {})
        else
          LabelGroup(
            children: [
              LabelRow(
                leading: Icon(
                  CupertinoIcons.creditcard,
                  color: method == PaymentMethod.card
                      ? colors.onInk
                      : colors.ink,
                ),
                title: l10n.card,
                selected: method == PaymentMethod.card,
                trailing: method == PaymentMethod.card
                    ? const Icon(CupertinoIcons.checkmark_alt)
                    : null,
                onTap: () => onMethod(PaymentMethod.card),
              ),
              LabelRow(
                leading: Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: method == PaymentMethod.cashOnDelivery
                      ? colors.onInk
                      : colors.ink,
                ),
                title: l10n.cashOnDelivery,
                selected: method == PaymentMethod.cashOnDelivery,
                trailing: method == PaymentMethod.cashOnDelivery
                    ? const Icon(CupertinoIcons.checkmark_alt)
                    : null,
                onTap: () => onMethod(PaymentMethod.cashOnDelivery),
              ),
            ],
          ),
        const SizedBox(height: DesignSpace.huge),
      ],
    );
  }
}
