import '../../domain/entities/sub_service.dart';

abstract final class SubServiceModel {
  static SubService fromJson(Map<String, dynamic> json) => SubService(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
  );
}
