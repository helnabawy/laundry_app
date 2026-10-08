import 'package:equatable/equatable.dart';

/// A laundry the customer can order from. Each one has its own catalogue,
/// prices, service levels, time slots and drivers.
class Laundry extends Equatable {
  const Laundry({
    required this.id,
    required this.name,
    this.slug = '',
    this.phone,
    this.logoUrl,
    this.address,
    this.city,
    this.area,
    this.codFee,
  });

  final String id;
  final String slug;

  /// Already in the request language.
  final String name;
  final String? phone;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? area;

  /// Cash-on-delivery handling fee, AED.
  final double? codFee;

  /// "Area, City" — whichever parts are known.
  String? get locality {
    final parts = [area, city].whereType<String>().where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    phone,
    logoUrl,
    address,
    city,
    area,
    codFee,
  ];
}
