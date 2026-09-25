import '../../domain/entities/item_condition.dart';

abstract final class ItemConditionModel {
  static ItemCondition fromJson(Map<String, dynamic> json) => ItemCondition(
    itemName: json['itemName'] as String,
    kind: ConditionKind.fromJson(json['kind'] as String),
    note: json['note'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}
