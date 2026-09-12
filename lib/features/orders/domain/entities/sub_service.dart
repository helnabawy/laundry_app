import 'package:equatable/equatable.dart';

/// A specific service under a [ServiceCategory], e.g. "Wash & Iron".
class SubService extends Equatable {
  const SubService({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;

  @override
  List<Object?> get props => [id, categoryId, name, description];
}
