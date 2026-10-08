import '../../domain/entities/laundry.dart';

/// JSON ↔ [Laundry]. Matches `GET /api/vendors` (laundry_admin
/// `src/server/api/serializers.ts`, `vendor()`).
abstract final class LaundryModel {
  static Laundry fromJson(Map<String, dynamic> json) => Laundry(
    id: json['id'] as String,
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String,
    phone: json['phone'] as String?,
    logoUrl: json['logoUrl'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    area: json['area'] as String?,
    codFee: (json['codFee'] as num?)?.toDouble(),
  );

  static Map<String, dynamic> toJson(Laundry l) => {
    'id': l.id,
    'slug': l.slug,
    'name': l.name,
    'phone': l.phone,
    'logoUrl': l.logoUrl,
    'address': l.address,
    'city': l.city,
    'area': l.area,
    'codFee': l.codFee,
  };
}
