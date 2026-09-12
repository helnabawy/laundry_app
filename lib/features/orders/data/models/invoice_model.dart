import '../../domain/entities/invoice.dart';
import 'order_item_model.dart';

abstract final class InvoiceModel {
  static Invoice fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String,
    items: (json['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(OrderItemModel.fromJson)
        .toList(),
    note: json['note'] as String?,
    paymentMethod: (json['paymentMethod'] as String?) != null
        ? PaymentMethod.fromJson(json['paymentMethod'] as String)
        : null,
    paid: json['paid'] as bool,
  );
}
