import '../../domain/entities/address.dart';

/// JSON mapping for `/api/me/addresses`.
abstract final class AddressModel {
  static Address fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    label: json['label'] as String?,
    city: json['city'] as String,
    area: json['area'] as String,
    building: json['building'] as String,
    floor: json['floor'] as String?,
    apartment: json['apartment'] as String,
    alternatePhone: json['alternatePhone'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  static Map<String, dynamic> toJson(NewAddress address) => {
    'label': address.label,
    'city': address.city,
    'area': address.area,
    'building': address.building,
    'floor': address.floor,
    'apartment': address.apartment,
    'alternatePhone': address.alternatePhone,
  };
}
