import 'package:equatable/equatable.dart';

import '../../../addresses/domain/entities/address.dart';
import 'laundry_order.dart';
import 'time_slot.dart';

enum TaskType { pickup, delivery }

/// One row in the driver's today list (plan §8.2 "مهام اليوم"): either a
/// pickup or a delivery for one order.
class DriverTask extends Equatable {
  const DriverTask({required this.type, required this.order});

  final TaskType type;
  final LaundryOrder order;

  String get orderId => order.id;
  int get orderNumber => order.number;
  Address get address => order.address;
  TimeSlot get slot =>
      type == TaskType.pickup ? order.pickupSlot : order.deliverySlot;

  @override
  List<Object?> get props => [type, order];
}
