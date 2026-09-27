import 'package:equatable/equatable.dart';

/// What happened to the order. The wording is rendered on the device from
/// the kind, so an inbox read after switching language reads in that language.
enum NotificationKind {
  // ---- Customer ----------------------------------------------------------
  driverAssigned,
  pickedUp,
  invoiceReady,
  processing,
  outForDelivery,
  delivered,
  pickupFailed,
  deliveryFailed,
  cancelled,

  // ---- Driver ------------------------------------------------------------
  newPickup,
  newDelivery,

  /// A kind this build doesn't know yet (a newer backend) — shown as a
  /// generic order update rather than dropped.
  update;

  static NotificationKind fromJson(String value) =>
      NotificationKind.values.firstWhere(
        (k) => k.name == value,
        orElse: () => NotificationKind.update,
      );
}

/// One message sent about one order, kept so it can be read again later.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.orderId,
    required this.orderNumber,
    required this.sentAt,
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String orderId;
  final int orderNumber;
  final DateTime sentAt;
  final bool read;

  @override
  List<Object?> get props => [id, kind, orderId, orderNumber, sentAt, read];
}
