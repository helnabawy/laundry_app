import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/item_condition.dart';
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

  /// Stains and damage must be seen before processing starts, and choosing a
  /// payment method is what starts it.
  var _acknowledged = false;

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
        // A shop-flow order (`lines.isEmpty`) has its price fixed and its
        // payment already chosen at checkout — this is a read-only receipt
        // for it, not the wizard flow's post-inspection payment step.
        final isShopOrder = order != null && order.lines.isEmpty;
        final mustAcknowledge =
            !isShopOrder &&
            invoice != null &&
            invoice.hasConditions &&
            !_acknowledged;

        return DetailPage(
          title: l10n.invoiceTitle,
          subtitle: invoice?.id.toUpperCase(),
          bottomBar:
              invoice == null || isShopOrder || invoice.paymentMethod != null
              ? null
              : ActionBar(
                  note: mustAcknowledge
                      ? l10n.acknowledgeConditionsFirst
                      : null,
                  children: [
                    ActionButton(
                      label: l10n.payAmount(
                        AppFormat.of(context).money(invoice.total),
                      ),
                      loading: state.paying,
                      onPressed: mustAcknowledge
                          ? null
                          : () => context
                                .read<OrderTrackingCubit>()
                                .choosePaymentMethod(
                                  _method,
                                  conditionsAcknowledged: _acknowledged,
                                ),
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
              : isShopOrder
              ? _ShopInvoiceBody(invoice: invoice)
              : _InvoiceBody(
                  order: order,
                  invoice: invoice,
                  method: _method,
                  onMethod: (m) => setState(() => _method = m),
                  acknowledged: _acknowledged,
                  onAcknowledged: (v) => setState(() => _acknowledged = v),
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
    required this.acknowledged,
    required this.onAcknowledged,
  });

  final LaundryOrder order;
  final Invoice invoice;
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethod;
  final bool acknowledged;
  final ValueChanged<bool> onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ConditionReport(
          invoice: invoice,
          acknowledged: acknowledged,
          onAcknowledged: onAcknowledged,
        ),

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

        // Not a direct line: FAQs, then the assistant, then — only if the
        // customer asks — a person.
        Padding(
          padding: const EdgeInsets.only(top: DesignSpace.xl),
          child: LabelGroup(
            children: [
              LabelRow(
                leading: Icon(
                  CupertinoIcons.question_circle,
                  color: colors.ink,
                ),
                title: l10n.invoiceInquiry,
                subtitle: l10n.invoiceInquiryNote,
                trailing: Icon(
                  CupertinoIcons.chevron_forward,
                  color: colors.inkTertiary,
                ),
                onTap: () => context.push(Routes.orderInvoiceHelp(order.id)),
              ),
            ],
          ),
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

/// What sorting turned up, shown before anything else on the invoice. The
/// customer is told in every case — including when nothing was found — and
/// must tick through any finding before choosing how to pay.
class _ConditionReport extends StatelessWidget {
  const _ConditionReport({
    required this.invoice,
    required this.acknowledged,
    required this.onAcknowledged,
  });

  final Invoice invoice;
  final bool acknowledged;
  final ValueChanged<bool> onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final awaitingDecision = invoice.paymentMethod == null;

    if (!invoice.hasConditions) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSpace.gutter,
          DesignSpace.xl,
          DesignSpace.gutter,
          0,
        ),
        child: NoticeBlock(
          tone: NoticeTone.done,
          glyph: const Icon(CupertinoIcons.checkmark_seal),
          title: l10n.noConditionsTitle,
          message: l10n.noConditionsBody,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (awaitingDecision)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.xl,
              DesignSpace.gutter,
              0,
            ),
            child: NoticeBlock(
              tone: NoticeTone.caution,
              glyph: const Icon(CupertinoIcons.exclamationmark_triangle),
              title: l10n.conditionsFoundTitle,
              message: l10n.conditionsFoundBody,
            ),
          ),
        LabelGroup(
          heading: l10n.conditionReport,
          children: [
            for (final condition in invoice.conditions)
              _ConditionRow(condition: condition),
            if (awaitingDecision)
              LabelRow(
                leading: Icon(
                  acknowledged
                      ? CupertinoIcons.checkmark_square_fill
                      : CupertinoIcons.square,
                  color: acknowledged ? colors.onInk : colors.ink,
                ),
                title: l10n.acknowledgeConditions,
                selected: acknowledged,
                onTap: () => onAcknowledged(!acknowledged),
              ),
          ],
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.condition});

  final ItemCondition condition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final kind = switch (condition.kind) {
      ConditionKind.stain => l10n.conditionStain,
      ConditionKind.damage => l10n.conditionDamage,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelRow(
          // Shape and word both carry the kind; colour never does alone.
          leading: Icon(switch (condition.kind) {
            ConditionKind.stain => CupertinoIcons.drop,
            ConditionKind.damage => CupertinoIcons.bandage,
          }, color: colors.signal),
          title: condition.itemName,
          subtitle: [kind, ?condition.note].join(' · '),
        ),
        if (condition.photoUrl case final url?)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DesignSpace.gutter,
              0,
              DesignSpace.gutter,
              DesignSpace.md,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignRadius.panel),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  semanticLabel: condition.itemName,
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: colors.tapeSunken),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A shop-flow order's invoice: read-only, since the price was fixed and the
/// payment already chosen at checkout — no conditions report (that's a
/// facility-inspection artifact the shop flow never produces) and no
/// payment-method chooser.
class _ShopInvoiceBody extends StatelessWidget {
  const _ShopInvoiceBody({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(
            l10n.itemsDetails,
            padding: const EdgeInsets.only(
              top: DesignSpace.xl,
              bottom: DesignSpace.belowHeading,
            ),
          ),
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
                value: format.money(invoice.subtotal),
              ),
              if (invoice.vipSurcharge > 0) ...[
                const StitchRule.dashed(),
                FieldLine(
                  label: l10n.vipSurchargeLabel,
                  value: format.money(invoice.vipSurcharge),
                ),
              ],
              if (invoice.codFee > 0) ...[
                const StitchRule.dashed(),
                FieldLine(
                  label: l10n.codFeeLabel,
                  value: format.money(invoice.codFee),
                ),
              ],
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
        LabelGroup(
          children: [
            LabelRow(
              leading: Icon(
                invoice.paymentMethod == PaymentMethod.card
                    ? CupertinoIcons.creditcard
                    : CupertinoIcons.money_dollar_circle,
                color: colors.ink,
              ),
              title: invoice.paymentMethod?.label(l10n) ?? '',
              subtitle: invoice.paid ? l10n.paid : l10n.unpaid,
            ),
          ],
        ),

        const SizedBox(height: DesignSpace.huge),
      ],
    );
  }
}
