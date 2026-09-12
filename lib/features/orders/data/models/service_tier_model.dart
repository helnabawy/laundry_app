import '../../domain/entities/service_tier.dart';

abstract final class ServiceTierModel {
  static ServiceTier fromJson(Map<String, dynamic> json) => ServiceTier(
    id: json['id'] as String,
    name: json['name'] as String,
    deliveryHours: json['deliveryHours'] as int,
    isVip: json['isVip'] as bool,
    perks: (json['perks'] as List<dynamic>).cast<String>(),
  );
}
