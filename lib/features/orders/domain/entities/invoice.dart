import 'package:equatable/equatable.dart';

import 'item_condition.dart';
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
    this.conditions = const [],
    this.note,
  });

  final String id;
  final List<OrderItem> items;

  /// Stains and damage found at sorting. Empty means the facility checked
  /// and found none.
  final List<ItemCondition> conditions;

  final String? note;
  final PaymentMethod? paymentMethod;
  final bool paid;

  double get total => items.fold(0, (sum, item) => sum + item.total);

  bool get hasConditions => conditions.isNotEmpty;

  Invoice copyWith({PaymentMethod? paymentMethod, bool? paid}) => Invoice(
    id: id,
    items: items,
    conditions: conditions,
    note: note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paid: paid ?? this.paid,
  );

  @override
  List<Object?> get props => [id, items, conditions, note, paymentMethod, paid];
}
