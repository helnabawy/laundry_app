import '../../domain/entities/service_category.dart';

abstract final class ServiceCategoryModel {
  static ServiceCategory fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
      );
}
