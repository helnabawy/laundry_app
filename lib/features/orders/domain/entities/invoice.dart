import 'package:equatable/equatable.dart';

import 'item_condition.dart';
import 'order_item.dart';

enum PaymentMethod {
  card,
  cashOnDelivery;

  static PaymentMethod fromJson(String value) =>
      PaymentMethod.values.firstWhere((m) => m.name == value);

  /// A flat handling fee for paying cash at the door — covers the driver
  /// carrying and reconciling cash, which a card charge doesn't need. The
  /// one place this number is defined, so the checkout's live preview and
  /// the order actually created from it can never drift apart.
  double get codFee => this == PaymentMethod.cashOnDelivery ? 5 : 0;
}

/// Issued by the facility after inspection (plan §3 `Invoice`) for the
/// wizard flow — the app never shows a price before this exists. For the
/// shop flow, the same entity is built immediately at checkout, with
/// [vipSurcharge] set from the chosen tier, [codFee] from the chosen
/// payment method, and no [conditions].
class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.items,
    required this.paymentMethod,
    required this.paid,
    this.conditions = const [],
    this.vipSurcharge = 0,
    this.codFee = 0,
    this.note,
  });

  final String id;
  final List<OrderItem> items;

  /// Stains and damage found at sorting. Empty means the facility checked
  /// and found none. Only ever populated by the wizard flow.
  final List<ItemCondition> conditions;

  final String? note;
  final PaymentMethod? paymentMethod;
  final bool paid;

  /// The chosen tier's surcharge on [subtotal] (0 for a non-VIP tier, and
  /// always 0 for wizard-flow invoices).
  final double vipSurcharge;

  /// [PaymentMethod.codFee] for whichever method was chosen — 0 for card.
  final double codFee;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get total => subtotal + vipSurcharge + codFee;

  bool get hasConditions => conditions.isNotEmpty;

  Invoice copyWith({PaymentMethod? paymentMethod, bool? paid}) => Invoice(
    id: id,
    items: items,
    conditions: conditions,
    vipSurcharge: vipSurcharge,
    codFee: codFee,
    note: note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paid: paid ?? this.paid,
  );

  @override
  List<Object?> get props => [
    id,
    items,
    conditions,
    vipSurcharge,
    codFee,
    note,
    paymentMethod,
    paid,
  ];
}
