import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/product.dart';
import '../../../orders/domain/entities/service_tier.dart';
import 'cart_line.dart';

/// The customer's in-progress shop order: a set of cart lines and an
/// optional service tier (VIP surcharge), fixed and priced before checkout
/// ever reaches the backend.
class Cart extends Equatable {
  const Cart({this.lines = const [], this.tier});

  final List<CartLine> lines;
  final ServiceTier? tier;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal => lines.fold(0, (sum, line) => sum + line.lineTotal);

  double get vipSurcharge => tier?.surchargeFor(subtotal) ?? 0;

  double get total => subtotal + vipSurcharge;

  int? quantityOf(String productId) => lines
      .where((line) => line.product.id == productId)
      .map((line) => line.quantity)
      .firstOrNull;

  /// Returns a new cart with [product]'s quantity set to [quantity]. A
  /// quantity of 0 or less removes the line entirely.
  Cart withQuantity(Product product, int quantity) {
    final next = [
      for (final line in lines)
        if (line.product.id != product.id) line,
    ];
    if (quantity > 0) next.add(CartLine(product: product, quantity: quantity));
    return Cart(lines: next, tier: tier);
  }

  Cart withTier(ServiceTier? tier) => Cart(lines: lines, tier: tier);

  @override
  List<Object?> get props => [lines, tier];
}
