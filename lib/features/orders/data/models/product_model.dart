import '../../domain/entities/product.dart';

abstract final class ProductModel {
  static Product fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    imageAsset: json['imageAsset'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}
