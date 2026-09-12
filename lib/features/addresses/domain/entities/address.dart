import 'package:equatable/equatable.dart';

/// Pickup / delivery address (step 1.4: area, building, apartment,
/// alternate phone).
class Address extends Equatable {
  const Address({
    required this.id,
    required this.city,
    required this.area,
    required this.building,
    required this.apartment,
    this.label,
    this.floor,
    this.alternatePhone,
    this.latitude,
    this.longitude,
  });

  final String id;
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

  @override
  List<Object?> get props => [
    id,
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

/// Input for creating an [Address].
class NewAddress extends Equatable {
  const NewAddress({
    required this.city,
    required this.area,
    required this.building,
    required this.apartment,
    this.label,
    this.floor,
    this.alternatePhone,
  });

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
    label,
    city,
    area,
    building,
    floor,
    apartment,
    alternatePhone,
  ];
}
