import 'package:equatable/equatable.dart';

import 'invoice.dart';

/// One requested category and the service chosen for it (wizard flow).
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

/// One cart line: a product and the quantity requested (shop flow).
class NewOrderItem extends Equatable {
  const NewOrderItem({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [productId, quantity];
}

/// Input for `CreateOrder` — mirrors `POST /api/orders`.
///
/// Exactly one of [lines] (wizard flow, price set later by the facility) or
/// [items] (shop flow, price fixed up front via [paymentMethod]) is non-empty.
class NewOrderParams extends Equatable {
  const NewOrderParams({
    this.lines = const [],
    this.items = const [],
    required this.tierId,
    this.paymentMethod,
    required this.pickupSlotId,
    required this.deliverySlotId,
    required this.addressId,
  });

  /// Wizard flow: one per category the customer is sending.
  final List<NewOrderLine> lines;

  /// Shop flow: the cart's products and their quantities.
  final List<NewOrderItem> items;

  final String tierId;

  /// Shop flow only — chosen at checkout, before pickup. Never set by the
  /// wizard flow (payment is chosen later, via `choosePaymentMethod`).
  final PaymentMethod? paymentMethod;

  final String pickupSlotId;
  final String deliverySlotId;
  final String addressId;

  @override
  List<Object?> get props => [
    lines,
    items,
    tierId,
    paymentMethod,
    pickupSlotId,
    deliverySlotId,
    addressId,
  ];
}
