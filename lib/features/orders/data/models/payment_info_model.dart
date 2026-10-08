import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment_info.dart';

abstract final class PaymentInfoModel {
  static PaymentInfo fromJson(Map<String, dynamic> json) => PaymentInfo(
    id: json['id'] as String,
    status: PaymentStatus.fromJson(json['status'] as String),
    provider: PaymentProvider.fromJson(json['provider'] as String),
    method: PaymentMethod.fromJson(json['method'] as String),
    amount: (json['amount'] as num).toDouble(),
    reference: json['reference'] as String?,
    checkoutUrl: json['checkoutUrl'] as String?,
    failureReason: json['failureReason'] as String?,
    paidAt: (json['paidAt'] as String?) != null
        ? DateTime.parse(json['paidAt'] as String)
        : null,
  );
}

abstract final class PaymentOptionModel {
  static PaymentOption fromJson(Map<String, dynamic> json) => PaymentOption(
    method: PaymentMethod.fromJson(json['method'] as String),
    provider: PaymentProvider.fromJson(json['provider'] as String),
    fee: (json['fee'] as num?)?.toDouble() ?? 0,
    minAmount: (json['minAmount'] as num?)?.toDouble(),
    maxAmount: (json['maxAmount'] as num?)?.toDouble(),
    installments: json['installments'] as int?,
  );
}
