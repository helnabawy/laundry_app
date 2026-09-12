import 'package:equatable/equatable.dart';

import '../../../addresses/domain/entities/address.dart';
import 'invoice.dart';
import 'order_status.dart';
import 'order_timeline_event.dart';
import 'service_category.dart';
import 'service_tier.dart';
import 'sub_service.dart';
import 'time_slot.dart';

/// A customer order (plan §3 `Order`), from creation through delivery.
class LaundryOrder extends Equatable {
  const LaundryOrder({
    required this.id,
    required this.number,
    required this.category,
    required this.subService,
    required this.tier,
    required this.pickupSlot,
    required this.deliverySlot,
    required this.address,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.createdAt,
    required this.timeline,
    this.driverName,
    this.invoice,
  });

  final String id;
  final int number;
  final ServiceCategory category;
  final SubService subService;
  final ServiceTier tier;
  final TimeSlot pickupSlot;
  final TimeSlot deliverySlot;
  final Address address;

  /// Shown to the driver on the pickup/delivery detail screens.
  final String customerName;
  final String customerPhone;

  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderTimelineEvent> timeline;
  final String? driverName;
  final Invoice? invoice;

  DateTime? timeOf(OrderStatus status) => timeline
      .cast<OrderTimelineEvent?>()
      .lastWhere((e) => e?.status == status, orElse: () => null)
      ?.at;

  @override
  List<Object?> get props => [
    id,
    number,
    category,
    subService,
    tier,
    pickupSlot,
    deliverySlot,
    address,
    customerName,
    customerPhone,
    status,
    createdAt,
    timeline,
    driverName,
    invoice,
  ];
}
