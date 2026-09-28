import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/invoice.dart';
import '../../../orders/domain/entities/laundry_order.dart';
import '../../../orders/presentation/pages/order_confirmation_view.dart';
import '../../domain/entities/cart.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/checkout_cubit.dart';
import '../widgets/reorder_countdown_view.dart';
import '../widgets/schedule_pickers.dart';

/// The shop flow's checkout, as two fields of the label being filled in
/// sequence: VIP + payment, then schedule + address. Mirrors the order
/// wizard's page shell shape, but is its own independent implementation —
/// one route hosting every step plus the confirmation, so the cubit's state
/// survives the whole flow.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, this.reorderFrom});

  /// A past shop-flow order to repeat: checkout opens filled from it.
  final LaundryOrder? reorderFrom;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // The cubit reads the cart internally, but the page's own widgets
        // (the live total, the itemized lines) watch it directly too.
        BlocProvider.value(value: sl<CartCubit>()),
        BlocProvider(create: (_) => sl<CheckoutCubit>(param1: reorderFrom)),
      ],
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (prev, curr) =>
          curr.failure != null && curr.failure != prev.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.failure!.localized(l10n))));
      },
      builder: (context, state) {
        if (state.created case final order?) {
          return OrderConfirmationView(order: order);
        }
        final cubit = context.read<CheckoutCubit>();
        final cart = context.watch<CartCubit>().state;

        switch (state.reorderStage) {
          // Until the order is sent, leaving the page by any route — Undo,
          // the back button, the edge swipe — is the undo.
          case ReorderStage.preparing || ReorderStage.countdown:
            return PopScope(
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) return;
                cubit.undoReorder();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.reorderUndone)));
              },
              child: state.reorderStage == ReorderStage.countdown
                  ? ReorderCountdownView(state: state, cubit: cubit, cart: cart)
                  : DetailPage(
                      title: l10n.reorder,
                      child: LoadingView(label: l10n.placingReorder),
                    ),
            );
          // Once sent there is nothing left to undo, so the page holds still.
          case ReorderStage.sending || ReorderStage.undone:
            return PopScope(
              canPop: false,
              child: DetailPage(
                title: l10n.reorder,
                child: LoadingView(label: l10n.placingReorder),
              ),
            );
          case null:
            break;
        }

        final title = state.step == 1 ? l10n.checkoutTitle : l10n.scheduleTitle;
        return PopScope(
          canPop: state.step == 1,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.previousStep();
          },
          child: FlowPage(
            title: title,
            step: state.step,
            totalSteps: 2,
            stepSemantics: l10n.stepOf(state.step, 2),
            onBack: state.step == 1 ? () => context.pop() : cubit.previousStep,
            bottomBar: ActionBar(
              children: [
                ActionButton(
                  label: state.step < 2 ? l10n.next : l10n.confirmOrder,
                  loading: state.submitting,
                  onPressed: state.canGoNext && !cart.isEmpty
                      ? cubit.nextStep
                      : null,
                ),
              ],
            ),
            child: switch (state.step) {
              1 => _PaymentStep(state: state, cubit: cubit, cart: cart),
              _ => _ScheduleStep(state: state, cubit: cubit),
            },
          ),
        );
      },
    );
  }
}

/// Step 1: VIP toggle + payment method, with a live, already-confirmed total.
class _PaymentStep extends StatelessWidget {
  const _PaymentStep({required this.state, required this.cubit, required this.cart});

  final CheckoutState state;
  final CheckoutCubit cubit;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppFormat.of(context);

    if (state.loadingTiers) return const LoadingView();
    if (state.failure != null && state.tiers.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(l10n),
        retryLabel: l10n.retry,
        onRetry: cubit.retry,
      );
    }

    final vipTier = state.vipTier;
    final vip = cubit.vip;

    return ListView(
      padding: const EdgeInsets.only(bottom: DesignSpace.huge),
      children: [
        LabelGroup(
          heading: l10n.itemsDetails,
          children: [
            for (final line in cart.lines)
              LabelRow(
                title: line.product.name,
                subtitle:
                    '${line.quantity} × ${format.money(line.product.unitPrice)}',
                value: format.money(line.lineTotal),
              ),
          ],
        ),
        if (vipTier != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignSpace.xl),
            child: LabelGroup(
              children: [
                LabelRow(
                  leading: AnimatedCareGlyphIcon(
                    CareGlyph.treat,
                    color: vip ? colors.onInk : colors.ink,
                    size: 26,
                    dots: vip ? 2 : 1,
                    bars: vip ? 2 : 1,
                  ),
                  title: l10n.vipSurchargeToggleTitle,
                  subtitle: l10n.vipSurchargeToggleSubtitle(vipTier.deliveryHours),
                  selected: vip,
                  trailing: vip
                      ? const Icon(CupertinoIcons.checkmark_alt)
                      : null,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    cubit.toggleVip(!vip);
                  },
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(l10n.paymentMethod),
        ),
        LabelGroup(
          children: [
            LabelRow(
              leading: Icon(
                CupertinoIcons.creditcard,
                color: state.paymentMethod == PaymentMethod.card
                    ? colors.onInk
                    : colors.ink,
              ),
              title: l10n.card,
              selected: state.paymentMethod == PaymentMethod.card,
              trailing: state.paymentMethod == PaymentMethod.card
                  ? const Icon(CupertinoIcons.checkmark_alt)
                  : null,
              onTap: () => cubit.selectPaymentMethod(PaymentMethod.card),
            ),
            LabelRow(
              leading: Icon(
                CupertinoIcons.money_dollar_circle,
                color: state.paymentMethod == PaymentMethod.cashOnDelivery
                    ? colors.onInk
                    : colors.ink,
              ),
              title: l10n.cashOnDelivery,
              subtitle: l10n.codFeeSubtitle(
                format.money(PaymentMethod.cashOnDelivery.codFee),
              ),
              selected: state.paymentMethod == PaymentMethod.cashOnDelivery,
              trailing: state.paymentMethod == PaymentMethod.cashOnDelivery
                  ? const Icon(CupertinoIcons.checkmark_alt)
                  : null,
              onTap: () =>
                  cubit.selectPaymentMethod(PaymentMethod.cashOnDelivery),
            ),
          ],
        ),
        if (state.paymentMethod.codFee > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.lg,
              DesignSpace.gutter,
              0,
            ),
            child: FieldLine(
              label: l10n.codFeeLabel,
              value: format.money(state.paymentMethod.codFee),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.xxl,
            DesignSpace.gutter,
            0,
          ),
          child: AmountSlot(
            label: l10n.total,
            placeholder: l10n.currencyAed('—.——'),
            amount: format.money(cart.total + state.paymentMethod.codFee),
          ),
        ),
      ],
    );
  }
}

/// Step 2: pickup/delivery schedule and address.
class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({required this.state, required this.cubit});

  final CheckoutState state;
  final CheckoutCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final tier = cubit.effectiveTier;

    return ListView(
      padding: const EdgeInsets.only(bottom: DesignSpace.huge),
      children: [
        if (state.reorderOf case final number?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.lg,
              DesignSpace.gutter,
              0,
            ),
            child: NoticeBlock(
              glyph: const Icon(CupertinoIcons.arrow_clockwise),
              title: l10n.reorderNoticeTitle(number.toString()),
              message: l10n.reorderNoticeBody,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(
            l10n.pickupTime,
            padding: const EdgeInsets.only(
              top: DesignSpace.xl,
              bottom: DesignSpace.belowHeading,
            ),
          ),
        ),
        DaySelector(
          section: 'pickup',
          selectedDay: state.pickupDay,
          dayCount: CheckoutCubit.scheduleDays,
          onSelected: cubit.selectPickupDay,
        ),
        const SizedBox(height: DesignSpace.lg),
        SlotGrid(
          section: 'pickup',
          loading: state.loadingPickupSlots,
          slots: state.pickupSlots,
          selected: state.pickupSlot,
          onSelected: cubit.selectPickupSlot,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(
            l10n.deliveryTime,
            trailing: tier == null
                ? null
                : Text(
                    l10n.basedOnTier(tier.name),
                    style: DesignTypography.fibreLine(colors.inkTertiary),
                  ),
          ),
        ),
        if (state.pickupSlot == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
            child: Text(
              l10n.selectPickupFirst,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.inkTertiary),
            ),
          )
        else ...[
          DaySelector(
            section: 'delivery',
            selectedDay: state.deliveryDay,
            minDay: state.pickupSlot!.start,
            dayCount: CheckoutCubit.scheduleDays,
            onSelected: cubit.selectDeliveryDay,
          ),
          const SizedBox(height: DesignSpace.lg),
          SlotGrid(
            section: 'delivery',
            loading: state.loadingDeliverySlots,
            slots: state.deliverySlots,
            selected: state.deliverySlot,
            onSelected: cubit.selectDeliverySlot,
          ),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: StampHeading(l10n.addressTitle),
        ),
        AddressPicker(
          addresses: state.addresses,
          loading: state.loadingAddresses,
          address: state.address,
          onSelected: cubit.selectAddress,
        ),
      ],
    );
  }
}
