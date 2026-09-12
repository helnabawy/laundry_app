import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order_status.dart';

enum StatusTone { info, warning, success, danger }

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

  StatusTone get tone => switch (this) {
    OrderStatus.delivered => StatusTone.success,
    OrderStatus.pickupFailed ||
    OrderStatus.deliveryFailed ||
    OrderStatus.cancelled => StatusTone.danger,
    OrderStatus.awaitingPayment => StatusTone.warning,
    _ => StatusTone.info,
  };
}

extension StatusToneColors on StatusTone {
  Color get foreground => switch (this) {
    StatusTone.info => AppColors.tealDark,
    StatusTone.warning => const Color(0xFF8A6220),
    StatusTone.success => AppColors.success,
    StatusTone.danger => AppColors.danger,
  };

  Color get background => switch (this) {
    StatusTone.info => AppColors.tealSoft,
    StatusTone.warning => AppColors.goldSoft,
    StatusTone.success => AppColors.successSoft,
    StatusTone.danger => AppColors.dangerSoft,
  };

  /// Dark, solid version used for the big status banner on the tracking page.
  Color get solid => switch (this) {
    StatusTone.info => AppColors.ink,
    StatusTone.warning => AppColors.gold,
    StatusTone.success => AppColors.success,
    StatusTone.danger => AppColors.danger,
  };
}
