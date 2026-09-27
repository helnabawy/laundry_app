import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/app_notification.dart';

/// How a notification reads: its words, and its mark in the glyph grammar —
/// the custody stage it is about, a bar beneath once the order is home, a
/// cross through when something didn't happen.
extension NotificationKindPresentation on NotificationKind {
  String title(AppLocalizations l10n) => switch (this) {
    NotificationKind.driverAssigned => l10n.notifDriverAssignedTitle,
    NotificationKind.pickedUp => l10n.notifPickedUpTitle,
    NotificationKind.invoiceReady => l10n.notifInvoiceReadyTitle,
    NotificationKind.processing => l10n.notifProcessingTitle,
    NotificationKind.outForDelivery => l10n.notifOutForDeliveryTitle,
    NotificationKind.delivered => l10n.notifDeliveredTitle,
    NotificationKind.pickupFailed => l10n.pickupFailedCustomerTitle,
    NotificationKind.deliveryFailed => l10n.notifDeliveryFailedTitle,
    NotificationKind.cancelled => l10n.notifCancelledTitle,
    NotificationKind.newPickup => l10n.notifNewPickupTitle,
    NotificationKind.newDelivery => l10n.notifNewDeliveryTitle,
    NotificationKind.update => l10n.notifUpdateTitle,
  };

  String body(AppLocalizations l10n, int orderNumber) {
    final number = orderNumber.toString();
    return switch (this) {
      NotificationKind.driverAssigned => l10n.notifDriverAssignedBody(number),
      NotificationKind.pickedUp => l10n.notifPickedUpBody(number),
      NotificationKind.invoiceReady => l10n.notifInvoiceReadyBody(number),
      NotificationKind.processing => l10n.notifProcessingBody(number),
      NotificationKind.outForDelivery => l10n.notifOutForDeliveryBody(number),
      NotificationKind.delivered => l10n.notifDeliveredBody(number),
      NotificationKind.pickupFailed => l10n.notifPickupFailedBody(number),
      NotificationKind.deliveryFailed => l10n.notifDeliveryFailedBody(number),
      NotificationKind.cancelled => l10n.notifCancelledBody(number),
      NotificationKind.newPickup => l10n.notifNewPickupBody(number),
      NotificationKind.newDelivery => l10n.notifNewDeliveryBody(number),
      NotificationKind.update => l10n.notifUpdateBody(number),
    };
  }

  CareGlyph get glyph => switch (this) {
    NotificationKind.driverAssigned ||
    NotificationKind.pickupFailed ||
    NotificationKind.newPickup => CareGlyph.collect,
    NotificationKind.pickedUp ||
    NotificationKind.cancelled ||
    NotificationKind.update => CareGlyph.custody,
    NotificationKind.invoiceReady => CareGlyph.inspect,
    NotificationKind.processing => CareGlyph.treat,
    NotificationKind.outForDelivery ||
    NotificationKind.delivered ||
    NotificationKind.deliveryFailed ||
    NotificationKind.newDelivery => CareGlyph.deliver,
  };

  bool get isFailure =>
      this == NotificationKind.pickupFailed ||
      this == NotificationKind.deliveryFailed ||
      this == NotificationKind.cancelled;

  bool get isComplete => this == NotificationKind.delivered;
}
