import 'package:equatable/equatable.dart';

/// Input for [CreateOrder] — mirrors `POST /api/orders` (plan §5).
class NewOrderParams extends Equatable {
  const NewOrderParams({
    required this.categoryId,
    required this.subServiceId,
    required this.tierId,
    required this.pickupSlotId,
    required this.deliverySlotId,
    required this.addressId,
  });

  final String categoryId;
  final String subServiceId;
  final String tierId;
  final String pickupSlotId;
  final String deliverySlotId;
  final String addressId;

  @override
  List<Object?> get props => [
    categoryId,
    subServiceId,
    tierId,
    pickupSlotId,
    deliverySlotId,
    addressId,
  ];
}
