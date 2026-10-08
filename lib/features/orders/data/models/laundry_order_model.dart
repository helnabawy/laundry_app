import '../../../addresses/data/models/address_model.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/order_line.dart';
import '../../domain/entities/order_rating.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_timeline_event.dart';
import '../../domain/entities/task_failure.dart';
import 'invoice_model.dart';
import 'service_category_model.dart';
import 'service_tier_model.dart';
import 'sub_service_model.dart';
import 'time_slot_model.dart';

abstract final class LaundryOrderModel {
  static LaundryOrder fromJson(Map<String, dynamic> json) => LaundryOrder(
    id: json['id'] as String,
    number: json['number'] as int,
    lines: _lines(json),
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
    failure: switch (json['failure']) {
      final Map<String, dynamic> f => TaskFailure(
        reason: TaskFailureReason.fromJson(f['reason'] as String),
        note: f['note'] as String?,
        photoUrl: f['photoUrl'] as String?,
      ),
      _ => null,
    },
    rating: switch (json['rating']) {
      final Map<String, dynamic> r => OrderRating(
        stars: r['stars'] as int,
        comment: r['comment'] as String?,
        ratedAt: DateTime.parse(r['ratedAt'] as String),
      ),
      _ => null,
    },
    laundryId: (json['vendor'] as Map<String, dynamic>?)?['id'] as String?,
    laundryName: (json['vendor'] as Map<String, dynamic>?)?['name'] as String?,
  );

  /// Reads the multi-line shape, falling back to the single `category` /
  /// `subService` pair an older payload sends so one backend version does not
  /// break the app. A shop order has no lines: `lines` is `[]` and there is no
  /// legacy pair, so it parses to an empty list.
  static List<OrderLine> _lines(Map<String, dynamic> json) {
    if (json['lines'] case final List<dynamic> raw
        when raw.isNotEmpty || json['category'] == null) {
      return raw
          .cast<Map<String, dynamic>>()
          .map(
            (e) => OrderLine(
              category: ServiceCategoryModel.fromJson(
                e['category'] as Map<String, dynamic>,
              ),
              subService: SubServiceModel.fromJson(
                e['subService'] as Map<String, dynamic>,
              ),
            ),
          )
          .toList();
    }
    if (json['category'] is! Map<String, dynamic>) return const [];
    return [
      OrderLine(
        category: ServiceCategoryModel.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
        subService: SubServiceModel.fromJson(
          json['subService'] as Map<String, dynamic>,
        ),
      ),
    ];
  }
}
