import 'package:equatable/equatable.dart';

import 'order_item.dart';

enum PaymentMethod {
  card,
  cashOnDelivery;

  static PaymentMethod fromJson(String value) =>
      PaymentMethod.values.firstWhere((m) => m.name == value);
}

/// Issued by the facility after inspection (plan §3 `Invoice`) — the app
/// never shows a price before this exists.
class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.items,
    required this.paymentMethod,
    required this.paid,
    this.note,
  });

  final String id;
  final List<OrderItem> items;
  final String? note;
  final PaymentMethod? paymentMethod;
  final bool paid;

  double get total => items.fold(0, (sum, item) => sum + item.total);

  @override
  List<Object?> get props => [id, items, note, paymentMethod, paid];
}
