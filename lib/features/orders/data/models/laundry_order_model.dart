import '../../../addresses/data/models/address_model.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_timeline_event.dart';
import 'invoice_model.dart';
import 'service_category_model.dart';
import 'service_tier_model.dart';
import 'sub_service_model.dart';
import 'time_slot_model.dart';

abstract final class LaundryOrderModel {
  static LaundryOrder fromJson(Map<String, dynamic> json) => LaundryOrder(
    id: json['id'] as String,
    number: json['number'] as int,
    category: ServiceCategoryModel.fromJson(
      json['category'] as Map<String, dynamic>,
    ),
    subService: SubServiceModel.fromJson(
      json['subService'] as Map<String, dynamic>,
    ),
    tier: ServiceTierModel.fromJson(json['tier'] as Map<String, dynamic>),
    pickupSlot: TimeSlotModel.fromJson(
      json['pickupSlot'] as Map<String, dynamic>,
    ),
    deliverySlot: TimeSlotModel.fromJson(
      json['deliverySlot'] as Map<String, dynamic>,
    ),
    address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
    customerName: json['customerName'] as String,
    customerPhone: json['customerPhone'] as String,
    status: OrderStatus.fromJson(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    timeline: (json['timeline'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (e) => OrderTimelineEvent(
            status: OrderStatus.fromJson(e['status'] as String),
            at: DateTime.parse(e['at'] as String),
          ),
        )
        .toList(),
    driverName: json['driverName'] as String?,
    invoice: (json['invoice'] as Map<String, dynamic>?) != null
        ? InvoiceModel.fromJson(json['invoice'] as Map<String, dynamic>)
        : null,
  );
}
