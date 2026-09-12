import '../../domain/entities/driver_task.dart';
import 'laundry_order_model.dart';

abstract final class DriverTaskModel {
  static DriverTask fromJson(Map<String, dynamic> json) => DriverTask(
    type: (json['type'] as String) == 'pickup' ? TaskType.pickup : TaskType.delivery,
    order: LaundryOrderModel.fromJson(json['order'] as Map<String, dynamic>),
  );
}
