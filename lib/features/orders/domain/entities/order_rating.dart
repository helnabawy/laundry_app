import 'package:equatable/equatable.dart';

/// The customer's rating of a delivered order (plan §9 Stage 5): stars plus
/// an optional note. Given once; the order carries it from then on.
class OrderRating extends Equatable {
  const OrderRating({required this.stars, this.comment, required this.ratedAt});

  static const maxStars = 5;

  /// 1…[maxStars].
  final int stars;
  final String? comment;
  final DateTime ratedAt;

  @override
  List<Object?> get props => [stars, comment, ratedAt];
}
