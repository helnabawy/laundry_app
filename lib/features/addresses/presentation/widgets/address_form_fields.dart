import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/address.dart';
import 'address_tile.dart';

/// Owns the controllers for an address form, optionally pre-filled from
/// [initial]. The parent owns the [Form] and disposes this.
class AddressFormData {
  AddressFormData([NewAddress? initial])
    : kind = ValueNotifier(initial?.kind ?? AddressKind.home),
      label = TextEditingController(text: initial?.label),
      city = TextEditingController(text: initial?.city),
      area = TextEditingController(text: initial?.area),
      building = TextEditingController(text: initial?.building),
      floor = TextEditingController(text: initial?.floor),
      apartment = TextEditingController(text: initial?.apartment),
      alternatePhone = TextEditingController(text: initial?.alternatePhone);

  final ValueNotifier<AddressKind> kind;
  final TextEditingController label;
  final TextEditingController city;
  final TextEditingController area;
  final TextEditingController building;
  final TextEditingController floor;
  final TextEditingController apartment;
  final TextEditingController alternatePhone;

  List<TextEditingController> get _all => [
    label,
    city,
    area,
    building,
    floor,
    apartment,
    alternatePhone,
  ];

  NewAddress toNewAddress() => NewAddress(
    kind: kind.value,
    // Only an "other" address carries its own name.
    label: kind.value == AddressKind.other ? _optional(label) : null,
    city: city.text.trim(),
    area: area.text.trim(),
    building: building.text.trim(),
    floor: _optional(floor),
    apartment: apartment.text.trim(),
    alternatePhone: _optional(alternatePhone),
  );

  void dispose() {
    kind.dispose();
    for (final c in _all) {
      c.dispose();
    }
  }

  static String? _optional(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }
}

/// A ruled field: the label stamped above the rule, the value written on it.
class LabelField extends StatelessWidget {
  const LabelField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.optionalNote,
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? optionalNote;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DesignTypography.stamp(colors.inkSecondary),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textDirection: textDirection,
            validator: validator,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      ),
    );
  }
}

class AddressFormFields extends StatelessWidget {
  const AddressFormFields({super.key, required this.data});

  final AddressFormData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? isRequired(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.requiredField : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KindField(data: data),
        LabelField(
          controller: data.city,
          label: l10n.city,
          validator: isRequired,
        ),
        LabelField(
          controller: data.area,
          label: l10n.area,
          validator: isRequired,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabelField(
                controller: data.building,
                label: l10n.building,
                validator: isRequired,
              ),
            ),
            const SizedBox(width: DesignSpace.lg),
            Expanded(
              child: LabelField(
                controller: data.apartment,
                label: l10n.apartment,
                validator: isRequired,
              ),
            ),
          ],
        ),
        LabelField(controller: data.floor, label: l10n.floor),
        LabelField(
          controller: data.alternatePhone,
          label: l10n.alternatePhone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

/// Home / Work / Other, and a name of the customer's own for "Other".
class _KindField extends StatelessWidget {
  const _KindField({required this.data});

  final AddressFormData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return ValueListenableBuilder(
      valueListenable: data.kind,
      builder: (context, kind, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addressType.toUpperCase(),
            style: DesignTypography.stamp(colors.inkSecondary),
          ),
          const SizedBox(height: DesignSpace.sm),
          SegmentedStrip(
            labels: [for (final k in AddressKind.values) k.localized(l10n)],
            index: kind.index,
            onChanged: (i) => data.kind.value = AddressKind.values[i],
          ),
          const SizedBox(height: DesignSpace.xl),
          if (kind == AddressKind.other)
            LabelField(controller: data.label, label: l10n.addressName),
        ],
      ),
    );
  }
}
