import 'package:equatable/equatable.dart';

enum ConditionKind {
  stain,
  damage;

  static ConditionKind fromJson(String value) =>
      ConditionKind.values.firstWhere((k) => k.name == value);
}

/// A stain or existing damage the facility found while sorting (step 4.2).
///
/// The customer is always told about these after sorting and before
/// processing starts, and acknowledges them on the invoice before choosing
/// a payment method.
class ItemCondition extends Equatable {
  const ItemCondition({
    required this.itemName,
    required this.kind,
    this.note,
    this.photoUrl,
  });

  final String itemName;
  final ConditionKind kind;
  final String? note;
  final String? photoUrl;

  @override
  List<Object?> get props => [itemName, kind, note, photoUrl];
}
