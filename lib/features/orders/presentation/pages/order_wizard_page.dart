import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/flow_header.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/labeled_rows.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/widgets/address_picker_sheet.dart';
import '../../../addresses/presentation/widgets/address_tile.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import '../cubit/order_wizard_cubit.dart';
import '../utils/category_icons.dart';
import 'order_confirmation_view.dart';

/// Order creation wizard (plan §8.1 steps 1-4 / §9 Stage 2). A single route
/// hosts all 4 steps plus the confirmation result, so the cubit's state
/// survives the whole flow.
class OrderWizardPage extends StatelessWidget {
  const OrderWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderWizardCubit>(),
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
      listenWhen: (prev, curr) => curr.failure != null && curr.failure != prev.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.failure!.localized(l10n))),
        );
      },
      builder: (context, state) {
        if (state.created != null) {
          return OrderConfirmationView(order: state.created!);
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
          child: Scaffold(
            body: Column(
              children: [
                FlowHeader(
                  title: title,
                  step: state.step,
                  onBack: state.step == 1 ? () => context.pop() : cubit.previousStep,
                ),
                Expanded(child: _StepBody(state: state, cubit: cubit)),
              ],
            ),
            bottomNavigationBar: BottomActions(
              children: [
                PrimaryButton(
                  label: state.step < 4 ? l10n.next : l10n.confirmOrder,
                  loading: state.submitting,
                  onPressed: state.canGoNext ? cubit.nextStep : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    return switch (state.step) {
      1 => _CategoryStep(state: state, cubit: cubit),
      2 => _SubServiceStep(state: state, cubit: cubit),
      3 => _TierStep(state: state, cubit: cubit),
      _ => _ScheduleStep(state: state, cubit: cubit),
    };
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadingCategories) return const LoadingView();
    if (state.failure != null && state.categories.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(context.l10n),
        onRetry: cubit.retry,
      );
    }
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: [
        for (final category in state.categories) _CategoryCard(category: category, state: state, cubit: cubit),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.state, required this.cubit});

  final ServiceCategory category;
  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final selected = category == state.category;
    return SelectableCard(
      selected: selected,
      onTap: () => cubit.selectCategory(category),
      child: Stack(
        children: [
          if (selected)
            const PositionedDirectional(
              top: 0,
              end: 0,
              child: SelectionIndicator(selected: true, size: 24),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(categoryIcon(category.id), size: 32, color: AppColors.ink),
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                category.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubServiceStep extends StatelessWidget {
  const _SubServiceStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadingSubServices) return const LoadingView();
    if (state.failure != null && state.subServices.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(context.l10n),
        onRetry: cubit.retry,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (state.category != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.category!.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        for (final sub in state.subServices) _SubServiceRow(sub: sub, state: state, cubit: cubit),
      ],
    );
  }
}

class _SubServiceRow extends StatelessWidget {
  const _SubServiceRow({required this.sub, required this.state, required this.cubit});

  final SubService sub;
  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final selected = sub == state.subService;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SelectableCard(
        selected: selected,
        onTap: () => cubit.selectSubService(sub),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(sub.description, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            SelectionIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _TierStep extends StatelessWidget {
  const _TierStep({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadingTiers) return const LoadingView();
    if (state.failure != null && state.tiers.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(context.l10n),
        onRetry: cubit.retry,
      );
    }
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final tier in state.tiers) _TierCard(tier: tier, state: state, cubit: cubit),
        const SizedBox(height: 8),
        InfoBanner(
          title: l10n.finalPriceTitle,
          message: l10n.finalPriceBody,
          tone: BannerTone.warning,
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.state, required this.cubit});

  final ServiceTier tier;
  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = tier == state.tier;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SelectableCard(
        selected: selected,
        onTap: () => cubit.selectTier(tier),
        borderColor: tier.isVip ? AppColors.gold : AppColors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tier.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                if (tier.isVip)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Pill(
                      label: l10n.fastest,
                      foreground: AppColors.gold,
                      background: AppColors.goldSoft,
                    ),
                  ),
                SelectionIndicator(selected: selected),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.deliveryWithin(tier.deliveryHours),
              style: const TextStyle(color: AppColors.muted),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            for (final perk in tier.perks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: tier.isVip ? AppColors.gold : AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Text(perk),
                  ],
                ),
              ),
          ],
        ),
      ),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.pickupTime,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _DaySelector(
          selectedDay: state.pickupDay,
          onSelected: cubit.selectPickupDay,
        ),
        const SizedBox(height: 12),
        _SlotGrid(
          loading: state.loadingPickupSlots,
          slots: state.pickupSlots,
          selected: state.pickupSlot,
          onSelected: cubit.selectPickupSlot,
        ),
        const SizedBox(height: 28),
        Text(
          l10n.deliveryTime,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (state.tier != null) ...[
          const SizedBox(height: 2),
          Text(
            l10n.basedOnTier(state.tier!.name),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
        const SizedBox(height: 10),
        if (state.pickupSlot == null)
          Text(l10n.selectPickupFirst, style: const TextStyle(color: AppColors.muted))
        else ...[
          _DaySelector(
            selectedDay: state.deliveryDay,
            minDay: state.pickupSlot!.start,
            onSelected: cubit.selectDeliveryDay,
          ),
          const SizedBox(height: 12),
          _SlotGrid(
            loading: state.loadingDeliverySlots,
            slots: state.deliverySlots,
            selected: state.deliverySlot,
            onSelected: cubit.selectDeliverySlot,
          ),
        ],
        const SizedBox(height: 28),
        Text(
          l10n.addressTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _AddressPicker(state: state, cubit: cubit),
      ],
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.selectedDay, required this.onSelected, this.minDay});

  final DateTime selectedDay;
  final DateTime? minDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final format = AppFormat.of(context);
    final start = DateUtils.dateOnly(minDay ?? DateTime.now());
    final days = List.generate(6, (i) => start.add(Duration(days: i)));
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final day = days[i];
          final selected = DateUtils.isSameDay(day, selectedDay);
          return _DayChip(
            weekday: format.weekday(day),
            dayNumber: day.day,
            selected: selected,
            onTap: () => onSelected(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
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
    return Material(
      color: selected ? AppColors.ink : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white70 : AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.ink,
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
    required this.loading,
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  final bool loading;
  final List<TimeSlot> slots;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = context.l10n;
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(l10n.noSlots, style: const TextStyle(color: AppColors.muted)),
      );
    }
    final format = AppFormat.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final slot in slots)
          _SlotChip(
            label: format.timeRange(slot.start, slot.end),
            isFull: slot.isFull,
            selected: slot == selected,
            onTap: slot.isFull ? null : () => onSelected(slot),
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
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
    final bg = isFull
        ? AppColors.disabled
        : selected
        ? AppColors.tealSoft
        : AppColors.surface;
    final border = selected ? AppColors.teal : AppColors.line;
    final fg = isFull ? AppColors.faint : AppColors.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? border : AppColors.line, width: selected ? 1.4 : 1),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
              if (isFull || selected) ...[
                const SizedBox(height: 2),
                Text(
                  isFull ? l10n.slotFull : l10n.slotSelected,
                  style: TextStyle(
                    fontSize: 11,
                    color: isFull ? AppColors.faint : AppColors.tealDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressPicker extends StatelessWidget {
  const _AddressPicker({required this.state, required this.cubit});

  final OrderWizardState state;
  final OrderWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.loadingAddresses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
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
      return AppCard(
        onTap: pick,
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_outlined, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.noAddress)),
          ],
        ),
      );
    }
    return AddressTile(
      address: address,
      selected: true,
      onTap: pick,
      trailing: TextButton(onPressed: pick, child: Text(l10n.change)),
    );
  }
}
