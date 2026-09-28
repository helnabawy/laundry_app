import 'package:equatable/equatable.dart';

/// A piece counted and priced by the facility after inspection (plan §3
/// `OrderItem`) — or, for the shop flow, a cart line snapshotted at checkout
/// time. [productId]/[categoryId] are only set by the shop flow; the wizard
/// flow's facility-generated items leave them null.
class OrderItem extends Equatable {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.categoryId,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final String? productId;
  final String? categoryId;

  double get total => quantity * unitPrice;

  @override
  List<Object?> get props => [name, quantity, unitPrice, productId, categoryId];
}
