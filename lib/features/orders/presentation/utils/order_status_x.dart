import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/order_status.dart';

extension OrderStatusPresentation on OrderStatus {
  String label(AppLocalizations l10n) => switch (this) {
    OrderStatus.pending => l10n.statusPending,
    OrderStatus.driverAssigned => l10n.statusDriverAssigned,
    OrderStatus.pickedUp => l10n.statusPickedUp,
    OrderStatus.atFacility => l10n.statusAtFacility,
    OrderStatus.awaitingPayment => l10n.statusAwaitingPayment,
    OrderStatus.processing => l10n.statusProcessing,
    OrderStatus.outForDelivery => l10n.statusOutForDelivery,
    OrderStatus.delivered => l10n.statusDelivered,
    OrderStatus.pickupFailed => l10n.statusPickupFailed,
    OrderStatus.deliveryFailed => l10n.statusDeliveryFailed,
    OrderStatus.cancelled => l10n.statusCancelled,
  };

  /// State is carried by form first. Only a genuine failure earns the signal
  /// colour; everything else is ink, quiet ink, or the hi-vis tag.
  StampTone get stampTone => switch (this) {
    OrderStatus.pickupFailed ||
    OrderStatus.deliveryFailed ||
    OrderStatus.cancelled => StampTone.alert,
    OrderStatus.delivered => StampTone.quiet,
    OrderStatus.awaitingPayment => StampTone.neutral,
    _ => StampTone.neutral,
  };

  /// Which of the five custody stages this status sits in.
  int get stageIndex => switch (this) {
    OrderStatus.pending ||
    OrderStatus.driverAssigned ||
    OrderStatus.pickupFailed ||
    OrderStatus.cancelled => 0,
    OrderStatus.pickedUp => 1,
    OrderStatus.atFacility || OrderStatus.awaitingPayment => 2,
    OrderStatus.processing => 3,
    OrderStatus.outForDelivery ||
    OrderStatus.delivered ||
    OrderStatus.deliveryFailed => 4,
  };
}

/// The five stages, in fixed order. The glyph row never changes shape — only
/// which glyph is filled, and how many bars sit beneath the ones behind it.
const custodyGlyphs = [
  CareGlyph.collect,
  CareGlyph.custody,
  CareGlyph.inspect,
  CareGlyph.treat,
  CareGlyph.deliver,
];

List<String> custodyLabels(AppLocalizations l10n) => [
  l10n.stageCollect,
  l10n.stageCustody,
  l10n.stageInspect,
  l10n.stageTreat,
  l10n.stageDeliver,
];

/// Builds the strip's stages for one order.
List<CustodyStage> custodyStagesFor(OrderStatus status, AppLocalizations l10n) {
  final labels = custodyLabels(l10n);
  final reached = status.stageIndex;
  final failed = status.isFailure;
  final complete = status == OrderStatus.delivered;

  return [
    for (var i = 0; i < custodyGlyphs.length; i++)
      CustodyStage(
        glyph: custodyGlyphs[i],
        label: labels[i],
        state: switch (i) {
          _ when failed && i == reached => StageState.failed,
          _ when complete => StageState.done,
          _ when i < reached => StageState.done,
          _ when i == reached => StageState.active,
          _ => StageState.upcoming,
        },
      ),
  ];
}

/// An unstarted strip: every glyph outline, nothing filled.
List<CustodyStage> blankCustodyStages(AppLocalizations l10n) {
  final labels = custodyLabels(l10n);
  return [
    for (var i = 0; i < custodyGlyphs.length; i++)
      CustodyStage(
        glyph: custodyGlyphs[i],
        label: labels[i],
        state: StageState.upcoming,
      ),
  ];
}
