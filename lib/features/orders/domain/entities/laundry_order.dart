import 'package:equatable/equatable.dart';

import '../../../addresses/domain/entities/address.dart';
import 'invoice.dart';
import 'order_line.dart';
import 'order_rating.dart';
import 'order_status.dart';
import 'order_timeline_event.dart';
import 'service_tier.dart';
import 'task_failure.dart';
import 'time_slot.dart';

/// A customer order (plan §3 `Order`), from creation through delivery.
class LaundryOrder extends Equatable {
  const LaundryOrder({
    required this.id,
    required this.number,
    required this.lines,
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
    this.failure,
    this.rating,
  });

  final String id;
  final int number;

  /// One entry per category in this collection, each with its own service —
  /// the wizard flow. Never empty for a wizard-flow order.
  ///
  /// Empty for a shop-flow order (built from a product cart instead, with
  /// [invoice] populated immediately) — this is the discriminator between
  /// the two flows.
  final List<OrderLine> lines;

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

  /// Set once the customer rates the delivered order.
  final OrderRating? rating;

  /// Only a delivered order can be rated, and only once.
  bool get canRate => status == OrderStatus.delivered && rating == null;

  /// The driver's report when a pickup or delivery couldn't happen.
  final TaskFailure? failure;

  /// The driver couldn't collect, so the order was cancelled and the customer
  /// has to book a new pickup time.
  bool get pickupFailedAndCancelled =>
      status == OrderStatus.cancelled &&
      timeOf(OrderStatus.pickupFailed) != null;

  /// `Clothes · Wash & Iron` for one line, `Clothes, Curtains` for several —
  /// the fibre line has no room to spell out a service per category.
  ///
  /// A shop-flow order has no [lines] (see its doc comment) — its invoice
  /// items stand in instead: the product name for one item, the item names
  /// joined for several.
  String get servicesLabel {
    if (lines.isEmpty) {
      final items = invoice!.items;
      return items.length == 1
          ? items.single.name
          : items.map((i) => i.name).join(', ');
    }
    return lines.length == 1
        ? lines.single.label
        : lines.map((l) => l.category.name).join(', ');
  }

  /// The glyph the order is represented by when only one mark fits.
  String get leadCategoryId => lines.isEmpty
      ? invoice!.items.first.categoryId!
      : lines.first.category.id;

  DateTime? timeOf(OrderStatus status) => timeline
      .cast<OrderTimelineEvent?>()
      .lastWhere((e) => e?.status == status, orElse: () => null)
      ?.at;

  @override
  List<Object?> get props => [
    id,
    number,
    lines,
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
    failure,
    rating,
  ];
}
