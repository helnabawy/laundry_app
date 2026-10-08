import 'package:equatable/equatable.dart';

import 'invoice.dart';

enum PaymentStatus {
  pending,
  succeeded,
  failed,
  cancelled,
  expired,
  partiallyRefunded,
  refunded;

  /// Unknown values (a newer backend) read as [failed]: the customer can
  /// always retry, and nothing claims money moved that may not have.
  static PaymentStatus fromJson(String value) => PaymentStatus.values
      .firstWhere((s) => s.name == value, orElse: () => PaymentStatus.failed);

  /// The money was taken (some of it may since have been refunded).
  bool get isCaptured =>
      this == succeeded || this == partiallyRefunded || this == refunded;

  /// The attempt ended without taking money; a new one can be started.
  bool get isUnsuccessful =>
      this == failed || this == cancelled || this == expired;
}

/// Who moves the money. `cash` is the driver collecting at the door.
enum PaymentProvider {
  networkIntl,
  telr,
  tabby,
  cash;

  static PaymentProvider fromJson(String value) => PaymentProvider.values
      .firstWhere((p) => p.name == value, orElse: () => PaymentProvider.cash);

  /// The brand shown to customers — a proper name, not translated.
  String get brand => switch (this) {
    PaymentProvider.networkIntl => 'N-Genius',
    PaymentProvider.telr => 'Telr',
    PaymentProvider.tabby => 'tabby',
    PaymentProvider.cash => '',
  };
}

/// One payment attempt on an invoice. Card and pay-later go through a hosted
/// checkout at [checkoutUrl]; the server confirms the outcome, never the app.
class PaymentInfo extends Equatable {
  const PaymentInfo({
    required this.id,
    required this.status,
    required this.provider,
    required this.method,
    required this.amount,
    this.reference,
    this.checkoutUrl,
    this.failureReason,
    this.paidAt,
  });

  final String id;
  final PaymentStatus status;
  final PaymentProvider provider;
  final PaymentMethod method;
  final double amount;

  /// The provider's transaction reference, as on the customer's receipt.
  final String? reference;

  /// Where to finish paying; only set while [status] is pending.
  final String? checkoutUrl;
  final String? failureReason;
  final DateTime? paidAt;

  bool get isPending => status == PaymentStatus.pending;

  PaymentInfo copyWith({PaymentStatus? status, String? failureReason}) =>
      PaymentInfo(
        id: id,
        status: status ?? this.status,
        provider: provider,
        method: method,
        amount: amount,
        reference: reference,
        checkoutUrl: status == null || status == PaymentStatus.pending
            ? checkoutUrl
            : null,
        failureReason: failureReason ?? this.failureReason,
        paidAt: paidAt,
      );

  @override
  List<Object?> get props => [
    id,
    status,
    provider,
    method,
    amount,
    reference,
    checkoutUrl,
    failureReason,
    paidAt,
  ];
}

/// A way the current laundry accepts payment, with any limits on the total.
class PaymentOption extends Equatable {
  const PaymentOption({
    required this.method,
    required this.provider,
    this.fee = 0,
    this.minAmount,
    this.maxAmount,
    this.installments,
  });

  final PaymentMethod method;
  final PaymentProvider provider;

  /// A handling fee added to the total (cash on delivery).
  final double fee;
  final double? minAmount;
  final double? maxAmount;

  /// Pay-later: how many equal parts the total is split into.
  final int? installments;

  bool accepts(double amount) =>
      (minAmount == null || amount >= minAmount!) &&
      (maxAmount == null || amount <= maxAmount!);

  @override
  List<Object?> get props => [
    method,
    provider,
    fee,
    minAmount,
    maxAmount,
    installments,
  ];
}
