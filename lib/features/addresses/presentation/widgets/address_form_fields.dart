import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/address.dart';

/// Owns the text controllers for an address form. The parent owns the
/// [Form] and disposes this.
class AddressFormData {
  final label = TextEditingController();
  final city = TextEditingController();
  final area = TextEditingController();
  final building = TextEditingController();
  final floor = TextEditingController();
  final apartment = TextEditingController();
  final alternatePhone = TextEditingController();

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
    label: _optional(label),
    city: city.text.trim(),
    area: area.text.trim(),
    building: building.text.trim(),
    floor: _optional(floor),
    apartment: apartment.text.trim(),
    alternatePhone: _optional(alternatePhone),
  );

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }

  static String? _optional(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }
}

class AddressFormFields extends StatelessWidget {
  const AddressFormFields({super.key, required this.data});

  final AddressFormData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.requiredField : null;

    Widget field(
      TextEditingController controller,
      String label, {
      bool isRequired = true,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label),
        validator: isRequired ? required : null,
      ),
    );

    return Column(
      children: [
        field(data.city, l10n.city),
        field(data.area, l10n.area),
        Row(
          children: [
            Expanded(child: field(data.building, l10n.building)),
            const SizedBox(width: 12),
            Expanded(
              child: field(
                data.apartment,
                l10n.apartment,
                keyboard: TextInputType.text,
              ),
            ),
          ],
        ),
        field(data.floor, l10n.floor, isRequired: false),
        field(
          data.alternatePhone,
          l10n.alternatePhone,
          isRequired: false,
          keyboard: TextInputType.phone,
        ),
        field(data.label, l10n.addressLabel, isRequired: false),
      ],
    );
  }
}
