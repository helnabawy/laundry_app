import 'package:equatable/equatable.dart';

/// A purchasable catalog item under a [ServiceCategory], priced up front —
/// e.g. "T-shirt — 2 EGP". Backs the shop flow's product grid, alongside the
/// wizard flow's category/sub-service selection.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.unitPrice,
    this.imageAsset,
    this.isActive = true,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double unitPrice;
  final String? imageAsset;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    categoryId,
    name,
    description,
    unitPrice,
    imageAsset,
    isActive,
  ];
}
