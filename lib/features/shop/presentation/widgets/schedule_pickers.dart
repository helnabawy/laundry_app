import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/widgets/address_picker_sheet.dart';
import '../../../addresses/presentation/widgets/address_tile.dart';
import '../../../orders/domain/entities/time_slot.dart';

/// Pickup/delivery day + slot pickers, and the address picker for the shop
/// flow's checkout — an independent implementation from the order wizard's
/// own schedule step (the two flows coexist rather than sharing code).

/// Days run along one strip; the chosen one inverts.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.section,
    required this.selectedDay,
    required this.onSelected,
    required this.dayCount,
    this.minDay,
  });

  final String section;
  final DateTime selectedDay;
  final DateTime? minDay;
  final int dayCount;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final format = AppFormat.of(context);
    final start = DateUtils.dateOnly(minDay ?? DateTime.now());
    final days = List.generate(
      dayCount,
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

class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
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

/// The pickup address, chosen from the saved set (or added on the spot when
/// there is none yet).
class AddressPicker extends StatelessWidget {
  const AddressPicker({
    super.key,
    required this.addresses,
    required this.loading,
    required this.address,
    required this.onSelected,
  });

  final List<Address> addresses;
  final bool loading;
  final Address? address;
  final ValueChanged<Address> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignSpace.lg),
        child: LoadingView(),
      );
    }

    Future<void> pick() async {
      final Address? result;
      if (addresses.isEmpty) {
        result = await context.push<Address>(Routes.addAddress);
      } else {
        result = await showAddressPicker(
          context,
          addresses: addresses,
          selected: address,
        );
      }
      if (result != null && context.mounted) onSelected(result);
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
    return LabelGroup(
      children: [
        AddressTile(
          address: address!,
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
