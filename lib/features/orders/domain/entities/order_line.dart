import 'package:equatable/equatable.dart';

import 'service_category.dart';
import 'sub_service.dart';

/// One category in an order, with the service chosen for it.
///
/// An order can carry several: sub-services are category-specific (only
/// carpets offer "Deep cleaning & wash"), so a customer sending clothes and
/// curtains in one collection picks a service for each.
class OrderLine extends Equatable {
  const OrderLine({required this.category, required this.subService});

  final ServiceCategory category;
  final SubService subService;

  /// `Clothes · Wash & Iron`
  String get label => '${category.name} · ${subService.name}';

  @override
  List<Object?> get props => [category, subService];
}
