import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/tokens/design_metrics.dart';
import '../../../../core/error/failures.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/domain/usecases/get_addresses.dart';
import '../../../orders/domain/entities/invoice.dart';
import '../../../orders/domain/entities/laundry_order.dart';
import '../../../orders/domain/entities/new_order_params.dart';
import '../../../orders/domain/entities/service_tier.dart';
import '../../../orders/domain/entities/time_slot.dart';
import '../../../orders/domain/usecases/catalog_usecases.dart';
import '../../../orders/domain/usecases/order_usecases.dart';
import 'cart_cubit.dart';

const _unset = Object();

/// Where a one-tap reorder stands. Absent once it has fallen back to the
/// steps (or for a fresh checkout).
enum ReorderStage {
  /// Loading the catalog and finding the soonest open windows.
  preparing,

  /// Everything is chosen and the order is held on the phone for the undo
  /// window; nothing has been sent yet.
  countdown,

  /// The undo window ran out and the order is being sent.
  sending,

  /// The customer undid it; nothing will be sent.
  undone,
}

/// Drives the shop flow's 2-step checkout: VIP toggle + payment method, then
/// pickup & delivery schedule + address. The cart itself (lines, tier,
/// totals) lives in [CartCubit] and is only read here, never duplicated.
///
/// This is an independent implementation from the order wizard's own
/// schedule/address step — the two flows coexist rather than sharing code.
class CheckoutState extends Equatable {
  CheckoutState({
    this.step = 1,
    this.tiers = const [],
    this.loadingTiers = true,
    this.paymentMethod = PaymentMethod.card,
    DateTime? pickupDay,
    this.pickupSlots = const [],
    this.loadingPickupSlots = false,
    this.pickupSlot,
    DateTime? deliveryDay,
    this.deliverySlots = const [],
    this.loadingDeliverySlots = false,
    this.deliverySlot,
    this.addresses = const [],
    this.loadingAddresses = false,
    this.address,
    this.submitting = false,
    this.failure,
    this.created,
    this.reorderOf,
    this.reorderStage,
  }) : pickupDay = pickupDay ?? DateUtils.dateOnly(DateTime.now()),
       deliveryDay = deliveryDay ?? DateUtils.dateOnly(DateTime.now());

  final int step;

  final List<ServiceTier> tiers;
  final bool loadingTiers;
  final PaymentMethod paymentMethod;

  final DateTime pickupDay;
  final List<TimeSlot> pickupSlots;
  final bool loadingPickupSlots;
  final TimeSlot? pickupSlot;

  final DateTime deliveryDay;
  final List<TimeSlot> deliverySlots;
  final bool loadingDeliverySlots;
  final TimeSlot? deliverySlot;

  final List<Address> addresses;
  final bool loadingAddresses;
  final Address? address;

  final bool submitting;
  final Failure? failure;
  final LaundryOrder? created;

  /// The past order's number when checkout was opened to repeat it.
  final int? reorderOf;

  /// Set while a one-tap reorder is placing itself.
  final ReorderStage? reorderStage;

  ServiceTier? get standardTier =>
      tiers.where((t) => !t.isVip).firstOrNull ?? tiers.firstOrNull;
  ServiceTier? get vipTier => tiers.where((t) => t.isVip).firstOrNull;

  bool get canGoNext => switch (step) {
    1 => tiers.isNotEmpty,
    2 => pickupSlot != null && deliverySlot != null && address != null,
    _ => false,
  };

  CheckoutState copyWith({
    int? step,
    List<ServiceTier>? tiers,
    bool? loadingTiers,
    PaymentMethod? paymentMethod,
    DateTime? pickupDay,
    List<TimeSlot>? pickupSlots,
    bool? loadingPickupSlots,
    Object? pickupSlot = _unset,
    DateTime? deliveryDay,
    List<TimeSlot>? deliverySlots,
    bool? loadingDeliverySlots,
    Object? deliverySlot = _unset,
    List<Address>? addresses,
    bool? loadingAddresses,
    Object? address = _unset,
    bool? submitting,
    Object? failure = _unset,
    Object? created = _unset,
    int? reorderOf,
    Object? reorderStage = _unset,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      tiers: tiers ?? this.tiers,
      loadingTiers: loadingTiers ?? this.loadingTiers,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pickupDay: pickupDay ?? this.pickupDay,
      pickupSlots: pickupSlots ?? this.pickupSlots,
      loadingPickupSlots: loadingPickupSlots ?? this.loadingPickupSlots,
      pickupSlot: identical(pickupSlot, _unset)
          ? this.pickupSlot
          : pickupSlot as TimeSlot?,
      deliveryDay: deliveryDay ?? this.deliveryDay,
      deliverySlots: deliverySlots ?? this.deliverySlots,
      loadingDeliverySlots: loadingDeliverySlots ?? this.loadingDeliverySlots,
      deliverySlot: identical(deliverySlot, _unset)
          ? this.deliverySlot
          : deliverySlot as TimeSlot?,
      addresses: addresses ?? this.addresses,
      loadingAddresses: loadingAddresses ?? this.loadingAddresses,
      address: identical(address, _unset) ? this.address : address as Address?,
      submitting: submitting ?? this.submitting,
      failure: identical(failure, _unset) ? this.failure : failure as Failure?,
      created: identical(created, _unset)
          ? this.created
          : created as LaundryOrder?,
      reorderOf: reorderOf ?? this.reorderOf,
      reorderStage: identical(reorderStage, _unset)
          ? this.reorderStage
          : reorderStage as ReorderStage?,
    );
  }

  @override
  List<Object?> get props => [
    step,
    tiers,
    loadingTiers,
    paymentMethod,
    pickupDay,
    pickupSlots,
    loadingPickupSlots,
    pickupSlot,
    deliveryDay,
    deliverySlots,
    loadingDeliverySlots,
    deliverySlot,
    addresses,
    loadingAddresses,
    address,
    submitting,
    failure,
    created,
    reorderOf,
    reorderStage,
  ];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required CartCubit cart,
    required GetProducts getProducts,
    required GetServiceTiers getTiers,
    required GetPickupSlots getPickupSlots,
    required GetDeliverySlots getDeliverySlots,
    required GetAddresses getAddresses,
    required CreateOrder createOrder,
    LaundryOrder? reorderFrom,
    this.undoWindow = DesignMotion.undoWindow,
  }) : _cart = cart,
       _getProducts = getProducts,
       _getTiers = getTiers,
       _getPickupSlots = getPickupSlots,
       _getDeliverySlots = getDeliverySlots,
       _getAddresses = getAddresses,
       _createOrder = createOrder,
       super(
         CheckoutState(
           reorderOf: reorderFrom?.number,
           reorderStage: reorderFrom == null ? null : ReorderStage.preparing,
         ),
       ) {
    if (reorderFrom case final source?) {
      _prefillFromReorder(source);
    } else {
      _loadTiers();
    }
  }

  /// How many days the pickup and delivery strips offer.
  static const scheduleDays = 6;

  /// How long a one-tap reorder waits on the phone before it is sent.
  final Duration undoWindow;
  Timer? _undoTimer;

  final CartCubit _cart;
  final GetProducts _getProducts;
  final GetServiceTiers _getTiers;
  final GetPickupSlots _getPickupSlots;
  final GetDeliverySlots _getDeliverySlots;
  final GetAddresses _getAddresses;
  final CreateOrder _createOrder;

  /// The tier the order will actually be priced against: the cart's chosen
  /// tier (set by the VIP toggle), or the non-VIP tier once loaded.
  ServiceTier? get effectiveTier => _cart.state.tier ?? state.standardTier;

  bool get vip => _cart.state.tier?.isVip ?? false;

  void toggleVip(bool value) => _cart.setTier(value ? state.vipTier : null);

  void selectPaymentMethod(PaymentMethod method) =>
      emit(state.copyWith(paymentMethod: method));

  Future<void> selectPickupDay(DateTime day) async {
    emit(
      state.copyWith(
        pickupDay: day,
        pickupSlot: null,
        deliverySlot: null,
        deliverySlots: const [],
      ),
    );
    await _loadPickupSlots();
  }

  Future<void> selectPickupSlot(TimeSlot slot) async {
    final tier = effectiveTier;
    if (tier == null) return;
    final notBefore = slot.start.add(Duration(hours: tier.deliveryHours));
    emit(
      state.copyWith(
        pickupSlot: slot,
        deliverySlot: null,
        deliveryDay: DateUtils.dateOnly(notBefore),
      ),
    );
    await _loadDeliverySlots();
  }

  Future<void> selectDeliveryDay(DateTime day) async {
    emit(state.copyWith(deliveryDay: day, deliverySlot: null));
    await _loadDeliverySlots();
  }

  void selectDeliverySlot(TimeSlot slot) =>
      emit(state.copyWith(deliverySlot: slot));

  void selectAddress(Address address) => emit(state.copyWith(address: address));

  Future<void> nextStep() async {
    if (state.submitting || !state.canGoNext) return;
    switch (state.step) {
      case 1:
        emit(state.copyWith(step: 2));
        await Future.wait([
          if (state.addresses.isEmpty) _loadAddresses(),
          if (state.pickupSlots.isEmpty) _loadPickupSlots(),
        ]);
      case 2:
        await _submit();
    }
  }

  void previousStep() {
    if (state.step > 1) {
      emit(state.copyWith(step: state.step - 1, failure: null));
    }
  }

  Future<void> retry() async {
    switch (state.step) {
      case 1:
        await _loadTiers();
      case 2:
        await Future.wait([
          if (state.addresses.isEmpty) _loadAddresses(),
          if (state.pickupSlots.isEmpty) _loadPickupSlots(),
        ]);
    }
  }

  /// Reorder: one tap on a past shop-flow order repopulates the cart from
  /// its invoice and places it again in the soonest open windows, after
  /// [undoWindow] in which it can still be undone or changed.
  Future<void> _prefillFromReorder(LaundryOrder source) async {
    final (productsResult, tiersResult, addressesResult) = await (
      _getProducts(),
      _getTiers(),
      _getAddresses(),
    ).wait;
    if (isClosed) return;

    final failure =
        productsResult.failureOrNull ??
        tiersResult.failureOrNull ??
        addressesResult.failureOrNull;
    final products = productsResult.valueOrNull ?? const [];
    final tiers = tiersResult.valueOrNull ?? const [];
    final addresses = addressesResult.valueOrNull ?? const [];

    _cart.loadFrom(source, products);

    final address =
        addresses.where((a) => a.id == source.address.id).firstOrNull ??
        addresses.firstOrNull;

    final step = _cart.state.isEmpty ? 1 : 2;

    emit(
      state.copyWith(
        step: step,
        tiers: tiers,
        loadingTiers: false,
        paymentMethod: source.invoice?.paymentMethod ?? PaymentMethod.card,
        addresses: addresses,
        address: address,
        failure: failure,
      ),
    );
    if (step == 2) await _preselectEarliestSlots();
    if (isClosed || state.reorderStage == ReorderStage.undone) return;
    if (state.step == 2 && state.canGoNext) {
      // Held on the phone, not sent: undoing leaves nothing to cancel.
      emit(state.copyWith(reorderStage: ReorderStage.countdown));
      _undoTimer = Timer(undoWindow, _sendReorder);
    } else {
      emit(state.copyWith(reorderStage: null));
    }
  }

  Future<void> _sendReorder() async {
    if (isClosed || state.reorderStage != ReorderStage.countdown) return;
    emit(state.copyWith(reorderStage: ReorderStage.sending));
    await _submit();
    if (!isClosed) emit(state.copyWith(reorderStage: null));
  }

  /// Undo within the window: nothing is sent. The page leaves right after.
  void undoReorder() {
    _undoTimer?.cancel();
    if (state.reorderStage
        case ReorderStage.preparing || ReorderStage.countdown) {
      emit(state.copyWith(reorderStage: ReorderStage.undone));
    }
  }

  /// Stop the countdown and hand the filled-in schedule to the customer.
  void editReorder() {
    if (state.reorderStage != ReorderStage.countdown) return;
    _undoTimer?.cancel();
    emit(state.copyWith(reorderStage: null));
  }

  @override
  Future<void> close() {
    _undoTimer?.cancel();
    return super.close();
  }

  Future<void> _preselectEarliestSlots() async {
    final tier = effectiveTier;
    if (tier == null) return;
    emit(state.copyWith(loadingPickupSlots: true));
    final today = DateUtils.dateOnly(DateTime.now());

    for (var i = 0; i < scheduleDays; i++) {
      final day = DateUtils.addDaysToDate(today, i);
      final result = await _getPickupSlots((day: day, tierId: tier.id));
      if (isClosed) return;
      if (result.failureOrNull case final f?) {
        emit(state.copyWith(loadingPickupSlots: false, failure: f));
        return;
      }
      final slots = result.valueOrNull!;
      final pickup = slots.where((s) => !s.isFull).firstOrNull;
      if (pickup == null) continue;

      emit(
        state.copyWith(
          pickupDay: day,
          pickupSlots: slots,
          loadingPickupSlots: false,
        ),
      );
      await selectPickupSlot(pickup);
      await _preselectEarliestDelivery(pickup, tier);
      return;
    }
    await _loadPickupSlots();
  }

  Future<void> _preselectEarliestDelivery(
    TimeSlot pickup,
    ServiceTier tier,
  ) async {
    final notBefore = pickup.start.add(Duration(hours: tier.deliveryHours));
    final firstDay = DateUtils.dateOnly(notBefore);
    final lastDay = DateUtils.addDaysToDate(
      DateUtils.dateOnly(pickup.start),
      scheduleDays - 1,
    );
    for (
      var day = firstDay;
      !day.isAfter(lastDay);
      day = DateUtils.addDaysToDate(day, 1)
    ) {
      if (isClosed) return;
      if (day != state.deliveryDay) await selectDeliveryDay(day);
      if (isClosed || state.loadingDeliverySlots) return;
      if (state.deliverySlots.where((s) => !s.isFull).firstOrNull
          case final slot?) {
        selectDeliverySlot(slot);
        return;
      }
    }
    if (!isClosed && state.deliveryDay != firstDay) {
      await selectDeliveryDay(firstDay);
    }
  }

  Future<void> _loadTiers() async {
    emit(state.copyWith(loadingTiers: true));
    final result = await _getTiers();
    emit(
      result.fold(
        onErr: (f) => state.copyWith(loadingTiers: false, failure: f),
        onOk: (tiers) => state.copyWith(tiers: tiers, loadingTiers: false),
      ),
    );
  }

  Future<void> _loadPickupSlots() async {
    final tier = effectiveTier;
    if (tier == null) return;
    emit(state.copyWith(loadingPickupSlots: true));
    final result = await _getPickupSlots((
      day: state.pickupDay,
      tierId: tier.id,
    ));
    emit(
      result.fold(
        onErr: (f) => state.copyWith(loadingPickupSlots: false, failure: f),
        onOk: (slots) =>
            state.copyWith(pickupSlots: slots, loadingPickupSlots: false),
      ),
    );
  }

  Future<void> _loadDeliverySlots() async {
    final tier = effectiveTier;
    final pickupSlot = state.pickupSlot;
    if (tier == null) return;
    final notBefore = pickupSlot != null
        ? pickupSlot.start.add(Duration(hours: tier.deliveryHours))
        : state.deliveryDay;
    emit(state.copyWith(loadingDeliverySlots: true));
    final result = await _getDeliverySlots((
      day: state.deliveryDay,
      tierId: tier.id,
      notBefore: notBefore,
    ));
    emit(
      result.fold(
        onErr: (f) => state.copyWith(loadingDeliverySlots: false, failure: f),
        onOk: (slots) =>
            state.copyWith(deliverySlots: slots, loadingDeliverySlots: false),
      ),
    );
  }

  Future<void> _loadAddresses() async {
    emit(state.copyWith(loadingAddresses: true));
    final result = await _getAddresses();
    emit(
      result.fold(
        onErr: (f) => state.copyWith(loadingAddresses: false, failure: f),
        onOk: (list) => state.copyWith(
          addresses: list,
          loadingAddresses: false,
          address: state.address ?? (list.isEmpty ? null : list.first),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final tier = effectiveTier;
    final pickupSlot = state.pickupSlot;
    final deliverySlot = state.deliverySlot;
    final address = state.address;
    final cart = _cart.state;
    if (tier == null ||
        pickupSlot == null ||
        deliverySlot == null ||
        address == null ||
        cart.isEmpty) {
      return;
    }
    emit(state.copyWith(submitting: true, failure: null));
    final result = await _createOrder(
      NewOrderParams(
        items: [
          for (final line in cart.lines)
            NewOrderItem(productId: line.product.id, quantity: line.quantity),
        ],
        tierId: tier.id,
        paymentMethod: state.paymentMethod,
        pickupSlotId: pickupSlot.id,
        deliverySlotId: deliverySlot.id,
        addressId: address.id,
      ),
    );
    if (isClosed) return;
    emit(
      result.fold(
        onErr: (f) => state.copyWith(submitting: false, failure: f),
        onOk: (order) {
          _cart.clear();
          return state.copyWith(submitting: false, created: order);
        },
      ),
    );
  }
}
