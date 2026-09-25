import 'package:equatable/equatable.dart';

/// What an address is to the customer. A customer can keep several (step 1.4).
enum AddressKind { home, work, other }

/// Pickup / delivery address (step 1.4: area, building, apartment,
/// alternate phone).
class Address extends Equatable {
  const Address({
    required this.id,
    required this.city,
    required this.area,
    required this.building,
    required this.apartment,
    this.kind = AddressKind.home,
    this.label,
    this.floor,
    this.alternatePhone,
    this.latitude,
    this.longitude,
  });

  final String id;
  final AddressKind kind;

  /// The customer's own name for an [AddressKind.other] address.
  final String? label;
  final String city;
  final String area;
  final String building;
  final String? floor;
  final String apartment;
  final String? alternatePhone;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// The editable fields, for pre-filling an edit form.
  NewAddress toNewAddress() => NewAddress(
    kind: kind,
    label: label,
    city: city,
    area: area,
    building: building,
    floor: floor,
    apartment: apartment,
    alternatePhone: alternatePhone,
  );

  @override
  List<Object?> get props => [
    id,
    kind,
    label,
    city,
    area,
    building,
    floor,
    apartment,
    alternatePhone,
    latitude,
    longitude,
  ];
}

/// Input for creating or editing an [Address].
class NewAddress extends Equatable {
  const NewAddress({
    required this.city,
    required this.area,
    required this.building,
    required this.apartment,
    this.kind = AddressKind.home,
    this.label,
    this.floor,
    this.alternatePhone,
  });

  final AddressKind kind;
  final String? label;
  final String city;
  final String area;
  final String building;
  final String? floor;
  final String apartment;
  final String? alternatePhone;

  bool get isComplete => [
    city,
    area,
    building,
    apartment,
  ].every((field) => field.trim().isNotEmpty);

  @override
  List<Object?> get props => [
    kind,
    label,
    city,
    area,
    building,
    floor,
    apartment,
    alternatePhone,
  ];
}
