import 'package:equatable/equatable.dart';

/// One of the 4 MVP categories (plan §1): clothes, home textiles, carpets,
/// curtains.
class ServiceCategory extends Equatable {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  @override
  List<Object?> get props => [id, name, description];
}
