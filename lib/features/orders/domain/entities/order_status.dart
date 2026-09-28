/// Order lifecycle (plan §9 "ملخص حالات الطلب").
///
/// `awaitingPayment` → `processing` → `outForDelivery` are driven by the
/// facility operator in the Admin Portal (Phase 4) and by Auto-Dispatch
/// (Phase 3) — neither exists yet, so the mock backend advances them
/// automatically after pickup/payment so the app can be demoed end-to-end.
/// A picked-up order that is already priced stays in `processing` for a
/// short wash window before it goes out for delivery.
enum OrderStatus {
  pending,
  driverAssigned,
  pickedUp,
  atFacility,
  awaitingPayment,
  processing,
  outForDelivery,
  delivered,
  pickupFailed,
  deliveryFailed,
  cancelled;

  static OrderStatus fromJson(String value) => OrderStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => OrderStatus.pending,
  );

  bool get isFailure => this == pickupFailed || this == deliveryFailed;
  bool get isPast => this == delivered || this == cancelled || isFailure;
  bool get isActive => !isPast;
}
