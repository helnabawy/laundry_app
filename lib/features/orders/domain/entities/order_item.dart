import 'package:equatable/equatable.dart';

/// A piece counted and priced by the facility after inspection (plan §3
/// `OrderItem`).
class OrderItem extends Equatable {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;

  @override
  List<Object?> get props => [name, quantity, unitPrice];
}
