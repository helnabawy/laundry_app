import 'package:equatable/equatable.dart';

/// Standard vs VIP (plan §1 "مستويين خدمة"). `deliveryHours` is the turnaround
/// used to filter delivery slots (plan step 2.5).
class ServiceTier extends Equatable {
  const ServiceTier({
    required this.id,
    required this.name,
    required this.deliveryHours,
    required this.isVip,
    required this.perks,
  });

  final String id;
  final String name;
  final int deliveryHours;
  final bool isVip;
  final List<String> perks;

  @override
  List<Object?> get props => [id, name, deliveryHours, isVip, perks];
}
