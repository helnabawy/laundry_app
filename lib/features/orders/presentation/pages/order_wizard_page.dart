import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/widgets/address_picker_sheet.dart';
import '../../../addresses/presentation/widgets/address_tile.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import '../cubit/order_wizard_cubit.dart';
import '../utils/category_icons.dart';
import 'order_confirmation_view.dart';

/// Order creation, as four fields of the label being filled in sequence.
///
/// A single route hosts all four steps plus the confirmation, so the cubit's
/// state survives the whole flow.
class OrderWizardPage extends StatelessWidget {
  const OrderWizardPage({super.key, this.reorderFrom});

  /// A past order to repeat: the wizard opens filled from it.
  final LaundryOrder? reorderFrom;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderWizardCubit>(param1: reorderFrom),
      child: const _OrderWizardView(),
    );
  }
}

class _OrderWizardView extends StatelessWidget {
  const _OrderWizardView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<OrderWizardCubit, OrderWizardState>(
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
        final cubit = context.read<OrderWizardCubit>();
        final title = switch (state.step) {
          1 => l10n.whatToWash,
          2 => l10n.serviceType,
          3 => l10n.serviceLevel,
          _ => l10n.scheduleTitle,
        };
        return PopScope(
          canPop: state.step == 1,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.previousStep();
          },
          child: FlowPage(
            title: title,
            step: state.step,
            stepSemantics: l10n.stepOf(state.step, 4),
            onBack: state.step == 1 ? () => context.pop() : cubit.previousStep,
            bottomBar: ActionBar(
              children: [
                ActionButton(
                  label: state.step < 4 ? l10n.next : l10n.confirmOrder,
                  loading: state.submitting,
                  onPressed: state.canGoNext ? cubit.nextStep : null,
                ),
              ],
            ),
            child: switch (state.step) {
              1 => _CategoryStep(state: state, cubit: cubit),
              2 => _SubServiceStep(state: state, cubit: cubit),
              3 => _TierStep(state: state, cubit: cubit),
              _ => _ScheduleStep(state: state, cubit: cubit),
            },
          ),
        );
      },
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (state.loadingCategories) return const LoadingView();
    if (state.failure != null && state.categories.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(l10n),
        retryLabel: l10n.retry,
        onRetry: cubit.retry,
      );
    }
    // The glyph family carries this step: the pictograms are the system's own
    // language for what a category is, and they stay legible at any Dynamic
    // Type size in a way a photographic card cannot.
    //
    // This is a multiple choice — one collection can carry clothes and
    // curtains — so the rows read as checkable rather than as one-of.
    return ListView(
      padding: const EdgeInsets.only(bottom: DesignSpace.huge),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.lg,
            DesignSpace.gutter,
            DesignSpace.md,
          ),
          child: Text(
            l10n.chooseAnyThatApply.toUpperCase(),
            style: DesignTypography.stamp(colors.inkSecondary),
          ),
        ),
        LabelGroup(
          children: [
            for (final category in state.categories)
              LabelRow(
                leading: CareGlyphIcon(
                  categoryGlyph(category.id),
                  color: state.isSelected(category) ? colors.onInk : colors.ink,
                  size: 28,
                ),
                title: category.name,
                subtitle: category.description,
                selected: state.isSelected(category),
                trailing: _CheckMark(checked: state.isSelected(category)),
                onTap: () => cubit.toggleCategory(category),
              ),
          ],
        ),
      ],
    );
  }
}

/// A checkbox in the system's own language: a ruled square that fills and
/// takes a mark, rather than a platform checkbox dropped into a label row.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: DesignMotion.quick,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? colors.onInk : const Color(0x00000000),
        border: Border.all(
          color: checked ? colors.onInk : colors.ruleStrong,
          width: DesignRule.medium,
        ),
        borderRadius: BorderRadius.circular(DesignRadius.slot),
      ),
      child: checked
          ? Icon(CupertinoIcons.checkmark_alt, size: 16, color: colors.ink)
          : null,
    );
  }
}

class _SubServiceStep extends StatelessWidget {
  const _SubServiceStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (state.loadingSubServices) return const LoadingView();
    if (state.failure != null && state.subServicesByCategory.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(l10n),
        retryLabel: l10n.retry,
        onRetry: cubit.retry,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: DesignSpace.huge),
      children: [
        // Services are category-specific, so each chosen category gets its own
        // group and its own choice. The photograph names the group.
        for (final category in state.selectedCategories) ...[
          switch (Photo.category(category.id)) {
            final image? => PhotoBand(
              image: image,
              aspectRatio: 3.2,
              scrim: ScrimWeight.light,
              child: Padding(
                padding: const EdgeInsets.all(DesignSpace.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: const Color(0xFFFFFFFF)),
                    ),
                  ],
                ),
              ),
            ),
            null => Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.gutter,
                DesignSpace.aboveHeading,
                DesignSpace.gutter,
                DesignSpace.belowHeading,
              ),
              child: Text(
                category.name.toUpperCase(),
                style: DesignTypography.stamp(colors.inkSecondary),
              ),
            ),
          },
          LabelGroup(
            children: [
              for (final sub
                  in state.subServicesByCategory[category.id] ??
                      const <SubService>[])
                LabelRow(
                  title: sub.name,
                  subtitle: sub.description,
                  selected: state.subServiceByCategory[category.id] == sub,
                  trailing: state.subServiceByCategory[category.id] == sub
                      ? const Icon(CupertinoIcons.checkmark_alt)
                      : null,
                  onTap: () => cubit.selectSubService(category.id, sub),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The signature moment: the level is not a card you pick, it is a modifier
/// you add. A dot appears inside the glyph, a bar slides beneath it, and the
/// turnaround re-sets in its own numeric slot without reflowing.
class _TierStep extends StatelessWidget {
  const _TierStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (state.loadingTiers) return const LoadingView();
    if (state.failure != null && state.tiers.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(l10n),
        retryLabel: l10n.retry,
        onRetry: cubit.retry,
      );
    }

    final tier = state.tier;
    final dots = tier == null ? 0 : (tier.isVip ? 2 : 1);
    final bars = tier == null ? 0 : (tier.isVip ? 2 : 1);

    return ListView(
      padding: const EdgeInsets.only(bottom: DesignSpace.huge),
      children: [
        TapeBand(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSpace.gutter,
            vertical: DesignSpace.xxl,
          ),
          child: Column(
            children: [
              AnimatedCareGlyphIcon(
                CareGlyph.treat,
                color: colors.ink,
                size: 62,
                dots: dots,
                bars: bars,
                semanticLabel: tier?.name,
              ),
              const SizedBox(height: DesignSpace.lg),
              AnimatedSwitcher(
                duration: DesignMotion.base,
                child: Text(
                  tier == null
                      ? l10n.serviceLevel.toUpperCase()
                      : l10n.deliveryWithin(tier.deliveryHours).toUpperCase(),
                  key: ValueKey(tier?.id ?? 'none'),
                  textAlign: TextAlign.center,
                  style: DesignTypography.stamp(colors.ink, size: 13),
                ),
              ),
            ],
          ),
        ),
        LabelGroup(
          children: [
            for (final t in state.tiers)
              LabelRow(
                leading: CareGlyphIcon(
                  CareGlyph.treat,
                  color: t == state.tier ? colors.onInk : colors.ink,
                  size: 26,
                  dots: t.isVip ? 2 : 1,
                  bars: t.isVip ? 2 : 1,
                ),
                title: t.name,
                subtitle: t.perks.join(' · '),
                value: '${t.deliveryHours}h',
                selected: t == state.tier,
                trailing: t == state.tier
                    ? const Icon(CupertinoIcons.checkmark_alt)
                    : null,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  cubit.selectTier(t);
                },
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.xxl,
            DesignSpace.gutter,
            0,
          ),
          child: AmountSlot(
            label: l10n.finalPriceTitle,
            placeholder: l10n.currencyAed('\u2014.\u2014\u2014'),
            pendingNote: l10n.finalPriceBody,
            emphasised: false,
          ),
        ),
      ],
    );
  }
}

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
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
        _DaySelector(
          section: 'pickup',
          selectedDay: state.pickupDay,
          onSelected: cubit.selectPickupDay,
        ),
        const SizedBox(height: DesignSpace.lg),
        _SlotGrid(
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
            trailing: state.tier == null
                ? null
                : Text(
                    l10n.basedOnTier(state.tier!.name),
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
          _DaySelector(
            section: 'delivery',
            selectedDay: state.deliveryDay,
            minDay: state.pickupSlot!.start,
            onSelected: cubit.selectDeliveryDay,
          ),
          const SizedBox(height: DesignSpace.lg),
          _SlotGrid(
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
        _AddressPicker(state: state, cubit: cubit),
      ],
    );
  }
}

/// Days run along one strip; the chosen one inverts.
class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.section,
    required this.selectedDay,
    required this.onSelected,
    this.minDay,
  });

  final String section;
  final DateTime selectedDay;
  final DateTime? minDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final format = AppFormat.of(context);
    final start = DateUtils.dateOnly(minDay ?? DateTime.now());
    final days = List.generate(
      OrderWizardCubit.scheduleDays,
      (i) => DateUtils.addDaysToDate(start, i),
    );
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignSpace.sm),
        itemBuilder: (context, i) {
          final day = days[i];
          return _DayField(
            key: ValueKey('$section-day-${day.toIso8601String()}'),
            weekday: format.weekday(day),
            dayNumber: day.day,
            selected: DateUtils.isSameDay(day, selectedDay),
            onTap: () => onSelected(day),
          );
        },
      ),
    );
  }
}

class _DayField extends StatelessWidget {
  const _DayField({
    super.key,
    required this.weekday,
    required this.dayNumber,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final int dayNumber;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$weekday $dayNumber',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: DesignMotion.quick,
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: DesignSpace.sm),
          decoration: BoxDecoration(
            color: selected ? colors.ink : const Color(0x00000000),
            border: Border.all(
              color: selected ? colors.ink : colors.rule,
              width: DesignRule.hair,
            ),
            borderRadius: BorderRadius.circular(DesignRadius.slot),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday.substring(0, weekday.length.clamp(0, 3)).toUpperCase(),
                style: DesignTypography.stamp(
                  selected ? colors.onInk : colors.inkTertiary,
                  size: 10,
                ),
              ),
              const SizedBox(height: DesignSpace.xxs),
              Text(
                '$dayNumber',
                style: DesignTypography.numeric(
                  selected ? colors.onInk : colors.ink,
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.section,
    required this.loading,
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  /// Distinguishes the pickup strip from the delivery strip, which
  /// legitimately offer the same times.
  final String section;
  final bool loading;
  final List<TimeSlot> slots;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignSpace.xxl),
        child: LoadingView(),
      );
    }
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSpace.gutter,
          vertical: DesignSpace.lg,
        ),
        child: Text(
          l10n.noSlots,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.inkTertiary),
        ),
      );
    }
    final format = AppFormat.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
      child: Wrap(
        spacing: DesignSpace.sm,
        runSpacing: DesignSpace.sm,
        children: [
          for (final slot in slots)
            _SlotField(
              key: ValueKey('$section-slot-${slot.start.toIso8601String()}'),
              label: format.timeRange(slot.start, slot.end),
              isFull: slot.isFull,
              selected: slot == selected,
              onTap: slot.isFull ? null : () => onSelected(slot),
            ),
        ],
      ),
    );
  }
}

/// A full slot wears the cross — the same modifier the system uses for every
/// refusal — so unavailability reads by form before colour.
class _SlotField extends StatelessWidget {
  const _SlotField({
    super.key,
    required this.label,
    required this.isFull,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool isFull;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final ink = isFull
        ? colors.inkDisabled
        : (selected ? colors.onInk : colors.ink);

    return Semantics(
      button: !isFull,
      enabled: !isFull,
      selected: selected,
      label: isFull ? '$label, ${l10n.slotFull}' : label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration: DesignMotion.quick,
          constraints: const BoxConstraints(minHeight: DesignSpace.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSpace.lg,
            vertical: DesignSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colors.ink
                : (isFull ? colors.tapeSunken : const Color(0x00000000)),
            border: Border.all(
              color: selected ? colors.ink : colors.rule,
              width: DesignRule.hair,
            ),
            borderRadius: BorderRadius.circular(DesignRadius.slot),
          ),
          child: Center(
            widthFactor: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  style: DesignTypography.numeric(
                    ink,
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                ),
                if (isFull)
                  Positioned.fill(
                    child: CustomPaint(painter: _StrikePainter(colors.signal)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = color
        ..strokeWidth = DesignRule.medium
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.color != color;
}

class _AddressPicker extends StatelessWidget {
  const _AddressPicker({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (state.loadingAddresses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignSpace.lg),
        child: LoadingView(),
      );
    }
    final address = state.address;

    Future<void> pick() async {
      final Address? result;
      if (state.addresses.isEmpty) {
        result = await context.push<Address>(Routes.addAddress);
      } else {
        result = await showAddressPicker(
          context,
          addresses: state.addresses,
          selected: address,
        );
      }
      if (result != null && context.mounted) cubit.selectAddress(result);
    }

    if (address == null) {
      return LabelGroup(
        children: [
          LabelRow(
            leading: Icon(CupertinoIcons.add, color: colors.tint),
            title: l10n.noAddress,
            onTap: pick,
          ),
        ],
      );
    }
    // Inversion means "chosen from a set". There is only one address here and
    // it is simply what the order will use, so it reads as an ordinary row
    // with a way to change it.
    return LabelGroup(
      children: [
        AddressTile(
          address: address,
          onTap: pick,
          trailing: Text(
            l10n.change.toUpperCase(),
            style: DesignTypography.stamp(colors.tint, size: 10.5),
          ),
        ),
      ],
    );
  }
}
