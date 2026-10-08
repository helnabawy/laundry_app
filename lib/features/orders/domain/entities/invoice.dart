import 'package:equatable/equatable.dart';

import 'item_condition.dart';
import 'order_item.dart';
import 'payment_info.dart';

enum PaymentMethod {
  card,
  cashOnDelivery,

  /// Buy now, pay later in four installments (Tabby).
  payLater;

  static PaymentMethod fromJson(String value) =>
      PaymentMethod.values.firstWhere((m) => m.name == value);

  /// Paid through a hosted checkout page rather than at the door.
  bool get isOnline => this != PaymentMethod.cashOnDelivery;

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
    this.paidAt,
    this.amountRefunded = 0,
    this.payment,
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

  final DateTime? paidAt;

  /// Sum of every refund the laundry has issued on this invoice.
  final double amountRefunded;

  /// The latest online payment attempt (or the cash collection), if any.
  final PaymentInfo? payment;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get total => subtotal + vipSurcharge + codFee;

  bool get hasConditions => conditions.isNotEmpty;

  /// Card or pay-later was chosen and the money isn't in yet: the customer
  /// still has a checkout to finish (or retry).
  bool get awaitingOnlinePayment => !paid && (paymentMethod?.isOnline ?? false);

  bool get isRefunded => amountRefunded > 0 && amountRefunded >= total;

  bool get isPartiallyRefunded => amountRefunded > 0 && amountRefunded < total;

  Invoice copyWith({
    PaymentMethod? paymentMethod,
    bool? paid,
    double? codFee,
    DateTime? paidAt,
    double? amountRefunded,
    PaymentInfo? payment,
  }) => Invoice(
    id: id,
    items: items,
    conditions: conditions,
    vipSurcharge: vipSurcharge,
    codFee: codFee ?? this.codFee,
    note: note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paid: paid ?? this.paid,
    paidAt: paidAt ?? this.paidAt,
    amountRefunded: amountRefunded ?? this.amountRefunded,
    payment: payment ?? this.payment,
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
    paidAt,
    amountRefunded,
    payment,
  ];
}
