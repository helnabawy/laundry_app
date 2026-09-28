import '../../domain/entities/order_item.dart';

abstract final class OrderItemModel {
  static OrderItem fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    productId: json['productId'] as String?,
    categoryId: json['categoryId'] as String?,
  );
}
