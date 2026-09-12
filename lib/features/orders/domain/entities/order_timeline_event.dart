import 'package:equatable/equatable.dart';

import 'order_status.dart';

/// One recorded status change, timestamped (plan §9 tracking timeline).
class OrderTimelineEvent extends Equatable {
  const OrderTimelineEvent({required this.status, required this.at});

  final OrderStatus status;
  final DateTime at;

  @override
  List<Object?> get props => [status, at];
}
