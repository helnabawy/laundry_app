import 'package:equatable/equatable.dart';

/// One requested category and the service chosen for it.
class NewOrderLine extends Equatable {
  const NewOrderLine({required this.categoryId, required this.subServiceId});

  final String categoryId;
  final String subServiceId;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'subServiceId': subServiceId,
  };

  @override
  List<Object?> get props => [categoryId, subServiceId];
}

/// Input for `CreateOrder` — mirrors `POST /api/orders`.
class NewOrderParams extends Equatable {
  const NewOrderParams({
    required this.lines,
    required this.tierId,
    required this.pickupSlotId,
    required this.deliverySlotId,
    required this.addressId,
  });

  /// At least one; one per category the customer is sending.
  final List<NewOrderLine> lines;

  final String tierId;
  final String pickupSlotId;
  final String deliverySlotId;
  final String addressId;

  @override
  List<Object?> get props => [
    lines,
    tierId,
    pickupSlotId,
    deliverySlotId,
    addressId,
  ];
}
