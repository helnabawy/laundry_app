import '../../domain/entities/invoice.dart';
import 'item_condition_model.dart';
import 'order_item_model.dart';

abstract final class InvoiceModel {
  static Invoice fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String,
    items: (json['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(OrderItemModel.fromJson)
        .toList(),
    conditions: ((json['conditions'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ItemConditionModel.fromJson)
        .toList(),
    note: json['note'] as String?,
    paymentMethod: (json['paymentMethod'] as String?) != null
        ? PaymentMethod.fromJson(json['paymentMethod'] as String)
        : null,
    vipSurcharge: (json['vipSurcharge'] as num?)?.toDouble() ?? 0,
    codFee: (json['codFee'] as num?)?.toDouble() ?? 0,
    paid: json['paid'] as bool,
  );
}
