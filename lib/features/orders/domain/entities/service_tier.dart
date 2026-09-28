import 'package:equatable/equatable.dart';

/// How a tier's cart-level surcharge is computed from the cart subtotal
/// (shop flow only; the wizard flow never calls [ServiceTier.surchargeFor]).
enum TierSurchargeType {
  none,
  flat,
  percentage;

  static TierSurchargeType fromJson(String value) => TierSurchargeType.values
      .firstWhere((t) => t.name == value, orElse: () => TierSurchargeType.none);
}

/// Standard vs VIP (plan §1 "مستويين خدمة"). `deliveryHours` is the turnaround
/// used to filter delivery slots (plan step 2.5). [surchargeType]/
/// [surchargeValue] back the shop flow's cart-level VIP surcharge, toggled at
/// checkout; they default to no surcharge so the wizard flow is unaffected.
class ServiceTier extends Equatable {
  const ServiceTier({
    required this.id,
    required this.name,
    required this.deliveryHours,
    required this.isVip,
    required this.perks,
    this.surchargeType = TierSurchargeType.none,
    this.surchargeValue = 0,
  });

  final String id;
  final String name;
  final int deliveryHours;
  final bool isVip;
  final List<String> perks;
  final TierSurchargeType surchargeType;
  final double surchargeValue;

  /// The surcharge this tier adds on top of [subtotal].
  double surchargeFor(double subtotal) => switch (surchargeType) {
    TierSurchargeType.none => 0,
    TierSurchargeType.flat => surchargeValue,
    TierSurchargeType.percentage => subtotal * surchargeValue / 100,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    deliveryHours,
    isVip,
    perks,
    surchargeType,
    surchargeValue,
  ];
}
