import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/product.dart';

/// One line in the cart: a product and how many of it.
class CartLine extends Equatable {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.unitPrice * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}
