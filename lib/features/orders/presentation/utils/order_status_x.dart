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

  /// Which of the five custody stages this status sits in (wizard flow —
  /// the facility inspects/prices/processes between pickup and delivery).
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

  /// Which of the four custody stages this status sits in for a shop-flow
  /// order — price is already fixed at checkout, so there's no facility
  /// inspection/payment wait, but the items are still actually washed, so
  /// that stage stays on the strip (`atFacility`/`awaitingPayment` never
  /// occur for this flow; they'd fold into "collected" if they somehow did).
  int get shopStageIndex => switch (this) {
    OrderStatus.pending ||
    OrderStatus.driverAssigned ||
    OrderStatus.pickupFailed ||
    OrderStatus.cancelled => 0,
    OrderStatus.pickedUp ||
    OrderStatus.atFacility ||
    OrderStatus.awaitingPayment => 1,
    OrderStatus.processing => 2,
    OrderStatus.outForDelivery ||
    OrderStatus.delivered ||
    OrderStatus.deliveryFailed => 3,
  };
}

/// The five stages, in fixed order, for a wizard-flow order. The glyph row
/// never changes shape — only which glyph is filled, and how many bars sit
/// beneath the ones behind it.
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

/// The four stages, in fixed order, for a shop-flow order — reuses the same
/// glyphs/labels as the wizard flow, minus the inspection/payment wait
/// (price is fixed at checkout), keeping the actual wash/treat stage.
const shopCustodyGlyphs = [
  CareGlyph.collect,
  CareGlyph.custody,
  CareGlyph.treat,
  CareGlyph.deliver,
];

List<String> shopCustodyLabels(AppLocalizations l10n) => [
  l10n.stageCollect,
  l10n.stageCustody,
  l10n.stageTreat,
  l10n.stageDeliver,
];

/// Builds the strip's stages for one order. [isShopOrder] selects the
/// shorter, shop-flow strip (pass `order.lines.isEmpty`); defaults to the
/// full wizard-flow strip.
List<CustodyStage> custodyStagesFor(
  OrderStatus status,
  AppLocalizations l10n, {
  bool isShopOrder = false,
}) {
  final glyphs = isShopOrder ? shopCustodyGlyphs : custodyGlyphs;
  final labels = isShopOrder ? shopCustodyLabels(l10n) : custodyLabels(l10n);
  final reached = isShopOrder ? status.shopStageIndex : status.stageIndex;
  final failed = status.isFailure;
  final complete = status == OrderStatus.delivered;

  return [
    for (var i = 0; i < glyphs.length; i++)
      CustodyStage(
        glyph: glyphs[i],
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

/// An unstarted strip: every glyph outline, nothing filled. [isShopOrder]
/// selects the shorter, shop-flow strip.
List<CustodyStage> blankCustodyStages(
  AppLocalizations l10n, {
  bool isShopOrder = false,
}) {
  final glyphs = isShopOrder ? shopCustodyGlyphs : custodyGlyphs;
  final labels = isShopOrder ? shopCustodyLabels(l10n) : custodyLabels(l10n);
  return [
    for (var i = 0; i < glyphs.length; i++)
      CustodyStage(
        glyph: glyphs[i],
        label: labels[i],
        state: StageState.upcoming,
      ),
  ];
}
