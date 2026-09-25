import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/domain/usecases/get_addresses.dart';
import '../../domain/entities/laundry_order.dart';
import '../../domain/entities/new_order_params.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/usecases/catalog_usecases.dart';
import '../../domain/usecases/order_usecases.dart';

const _unset = Object();

/// Drives the 4-step order creation wizard (plan §8.1 / §9 Stage 2): service
/// category → sub-service → tier → pickup & delivery schedule + address.
class OrderWizardState extends Equatable {
  OrderWizardState({
    this.step = 1,
    this.categories = const [],
    this.loadingCategories = true,
    this.selectedCategories = const [],
    this.subServicesByCategory = const {},
    this.loadingSubServices = false,
    this.subServiceByCategory = const {},
    this.tiers = const [],
    this.loadingTiers = false,
    this.tier,
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
  }) : pickupDay = pickupDay ?? DateUtils.dateOnly(DateTime.now()),
       deliveryDay = deliveryDay ?? DateUtils.dateOnly(DateTime.now());

  final int step;

  final List<ServiceCategory> categories;
  final bool loadingCategories;

  /// What the customer is sending. Several categories can travel in one
  /// collection, so this is a list, in the order they were chosen.
  final List<ServiceCategory> selectedCategories;

  /// Sub-services are category-specific, so they are loaded and held per
  /// category rather than as one flat list.
  final Map<String, List<SubService>> subServicesByCategory;
  final bool loadingSubServices;

  /// The service chosen for each selected category, keyed by category id.
  final Map<String, SubService> subServiceByCategory;

  bool isSelected(ServiceCategory c) => selectedCategories.contains(c);

  final List<ServiceTier> tiers;
  final bool loadingTiers;
  final ServiceTier? tier;

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

  /// The past order's number when the wizard was opened to repeat it, so the
  /// schedule step can say what it was filled from.
  final int? reorderOf;

  /// Every chosen category has a service picked for it.
  bool get everyCategoryServiced =>
      selectedCategories.isNotEmpty &&
      selectedCategories.every((c) => subServiceByCategory[c.id] != null);

  bool get canGoNext => switch (step) {
    1 => selectedCategories.isNotEmpty,
    2 => everyCategoryServiced,
    3 => tier != null,
    4 => pickupSlot != null && deliverySlot != null && address != null,
    _ => false,
  };

  OrderWizardState copyWith({
    int? step,
    List<ServiceCategory>? categories,
    bool? loadingCategories,
    List<ServiceCategory>? selectedCategories,
    Map<String, List<SubService>>? subServicesByCategory,
    bool? loadingSubServices,
    Map<String, SubService>? subServiceByCategory,
    List<ServiceTier>? tiers,
    bool? loadingTiers,
    Object? tier = _unset,
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
  }) {
    return OrderWizardState(
      step: step ?? this.step,
      categories: categories ?? this.categories,
      loadingCategories: loadingCategories ?? this.loadingCategories,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      subServicesByCategory:
          subServicesByCategory ?? this.subServicesByCategory,
      loadingSubServices: loadingSubServices ?? this.loadingSubServices,
      subServiceByCategory: subServiceByCategory ?? this.subServiceByCategory,
      tiers: tiers ?? this.tiers,
      loadingTiers: loadingTiers ?? this.loadingTiers,
      tier: identical(tier, _unset) ? this.tier : tier as ServiceTier?,
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
      reorderOf: reorderOf,
    );
  }

  @override
  List<Object?> get props => [
    step,
    categories,
    loadingCategories,
    selectedCategories,
    subServicesByCategory,
    loadingSubServices,
    subServiceByCategory,
    tiers,
    loadingTiers,
    tier,
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
  ];
}

class OrderWizardCubit extends Cubit<OrderWizardState> {
  OrderWizardCubit({
    required GetServiceCategories getCategories,
    required GetSubServices getSubServices,
    required GetServiceTiers getTiers,
    required GetPickupSlots getPickupSlots,
    required GetDeliverySlots getDeliverySlots,
    required GetAddresses getAddresses,
    required CreateOrder createOrder,
    LaundryOrder? reorderFrom,
  }) : _getCategories = getCategories,
       _getSubServices = getSubServices,
       _getTiers = getTiers,
       _getPickupSlots = getPickupSlots,
       _getDeliverySlots = getDeliverySlots,
       _getAddresses = getAddresses,
       _createOrder = createOrder,
       super(OrderWizardState(reorderOf: reorderFrom?.number)) {
    if (reorderFrom case final source?) {
      _prefillFrom(source);
    } else {
      _loadCategories();
    }
  }

  /// How many days the pickup and delivery strips offer.
  static const scheduleDays = 6;

  final GetServiceCategories _getCategories;
  final GetSubServices _getSubServices;
  final GetServiceTiers _getTiers;
  final GetPickupSlots _getPickupSlots;
  final GetDeliverySlots _getDeliverySlots;
  final GetAddresses _getAddresses;
  final CreateOrder _createOrder;

  /// Categories are a multiple choice: one collection can carry clothes and
  /// curtains. Deselecting drops that category's chosen service with it.
  void toggleCategory(ServiceCategory category) {
    final selected = [...state.selectedCategories];
    final services = {...state.subServiceByCategory};
    if (selected.remove(category)) {
      services.remove(category.id);
      emit(
        state.copyWith(
          selectedCategories: selected,
          subServiceByCategory: services,
        ),
      );
      return;
    }
    selected.add(category);
    emit(state.copyWith(selectedCategories: selected));
  }

  void selectSubService(String categoryId, SubService subService) => emit(
    state.copyWith(
      subServiceByCategory: {
        ...state.subServiceByCategory,
        categoryId: subService,
      },
    ),
  );

  /// Loads the service list for every chosen category, skipping any already
  /// held so stepping back and forward does not refetch.
  Future<void> _loadSubServicesForSelection() async {
    final missing = state.selectedCategories
        .where((c) => !state.subServicesByCategory.containsKey(c.id))
        .toList();
    if (missing.isEmpty) return;

    emit(state.copyWith(loadingSubServices: true));
    final loaded = {...state.subServicesByCategory};
    Failure? failure;
    for (final category in missing) {
      final result = await _getSubServices(category.id);
      result.fold(
        onErr: (f) => failure ??= f,
        onOk: (list) => loaded[category.id] = list,
      );
    }
    emit(
      state.copyWith(
        subServicesByCategory: loaded,
        loadingSubServices: false,
        failure: failure,
      ),
    );
  }

  void selectTier(ServiceTier tier) => emit(
    state.copyWith(
      tier: tier,
      pickupSlot: null,
      deliverySlot: null,
      pickupSlots: const [],
      deliverySlots: const [],
    ),
  );

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
    final tier = state.tier;
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
        await _loadSubServicesForSelection();
      case 2:
        emit(state.copyWith(step: 3));
        if (state.tiers.isEmpty) await _loadTiers();
      case 3:
        emit(state.copyWith(step: 4));
        await Future.wait([
          if (state.addresses.isEmpty) _loadAddresses(),
          if (state.pickupSlots.isEmpty) _loadPickupSlots(),
        ]);
      case 4:
        await _submit();
    }
  }

  void previousStep() {
    if (state.step > 1)
      emit(state.copyWith(step: state.step - 1, failure: null));
  }

  /// Retries whatever load is missing for the current step.
  Future<void> retry() async {
    switch (state.step) {
      case 1:
        await _loadCategories();
      case 2:
        await _loadSubServicesForSelection();
      case 3:
        await _loadTiers();
      case 4:
        await Future.wait([
          if (state.addresses.isEmpty) _loadAddresses(),
          if (state.pickupSlots.isEmpty) _loadPickupSlots(),
        ]);
    }
  }

  /// Reorder (plan §9 Stage 5): one tap on a past order lands here with its
  /// categories, services, level and address already chosen and the soonest
  /// open windows picked, so confirming is all that is left.
  ///
  /// Everything is matched against today's catalog by id: whatever it no
  /// longer offers is left unchosen and the wizard opens on that step instead.
  Future<void> _prefillFrom(LaundryOrder source) async {
    final categoryIds = [for (final line in source.lines) line.category.id];
    final (
      categoriesResult,
      tiersResult,
      addressesResult,
      servicesResults,
    ) = await (
      _getCategories(),
      _getTiers(),
      _getAddresses(),
      Future.wait([for (final id in categoryIds) _getSubServices(id)]),
    ).wait;
    if (isClosed) return;

    final failure =
        categoriesResult.failureOrNull ??
        tiersResult.failureOrNull ??
        addressesResult.failureOrNull ??
        servicesResults.map((r) => r.failureOrNull).nonNulls.firstOrNull;
    final categories = categoriesResult.valueOrNull ?? const [];
    final tiers = tiersResult.valueOrNull ?? const [];
    final addresses = addressesResult.valueOrNull ?? const [];
    final servicesByCategory = {
      for (final (i, id) in categoryIds.indexed)
        id: ?servicesResults[i].valueOrNull,
    };

    final selected = [
      for (final line in source.lines)
        ?categories.where((c) => c.id == line.category.id).firstOrNull,
    ];
    final chosenServices = {
      for (final line in source.lines)
        line.category.id: ?servicesByCategory[line.category.id]
            ?.where((s) => s.id == line.subService.id)
            .firstOrNull,
    };
    final tier = tiers.where((t) => t.id == source.tier.id).firstOrNull;
    final address =
        addresses.where((a) => a.id == source.address.id).firstOrNull ??
        addresses.firstOrNull;

    final allCategories =
        selected.isNotEmpty && selected.length == source.lines.length;
    final step = switch ((allCategories, chosenServices.length)) {
      (false, _) => 1,
      (_, final n) when n < selected.length => 2,
      _ when tier == null => 3,
      _ => 4,
    };

    emit(
      state.copyWith(
        step: step,
        categories: categories,
        loadingCategories: false,
        selectedCategories: selected,
        subServicesByCategory: servicesByCategory,
        subServiceByCategory: chosenServices,
        tiers: tiers,
        tier: tier,
        addresses: addresses,
        address: address,
        failure: failure,
      ),
    );
    if (step == 4) await _preselectEarliestSlots();
  }

  /// Picks the first open pickup window within the strip, then the first open
  /// delivery window the level allows after it. Either can still be changed;
  /// if nothing is open the customer is left to choose as usual.
  Future<void> _preselectEarliestSlots() async {
    final tier = state.tier;
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
    // Nothing open this week: show today's strip and let the customer look.
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
    // None open in the strip: go back to the earliest day, still unchosen.
    if (!isClosed && state.deliveryDay != firstDay) {
      await selectDeliveryDay(firstDay);
    }
  }

  Future<void> _loadCategories() async {
    emit(state.copyWith(loadingCategories: true));
    final result = await _getCategories();
    emit(
      result.fold(
        onErr: (f) => state.copyWith(loadingCategories: false, failure: f),
        onOk: (categories) =>
            state.copyWith(categories: categories, loadingCategories: false),
      ),
    );
  }

  Future<void> _loadTiers() async {
    emit(state.copyWith(loadingTiers: true));
    final result = await _getTiers();
    emit(
      result.fold(
        onErr: (f) => state.copyWith(loadingTiers: false, failure: f),
        onOk: (tiers) {
          final preselected =
              state.tier ??
              (tiers.isEmpty
                  ? null
                  : tiers.firstWhere(
                      (t) => !t.isVip,
                      orElse: () => tiers.first,
                    ));
          return state.copyWith(
            tiers: tiers,
            loadingTiers: false,
            tier: preselected,
          );
        },
      ),
    );
  }

  Future<void> _loadPickupSlots() async {
    final tier = state.tier;
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
    final tier = state.tier;
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
    final tier = state.tier;
    final pickupSlot = state.pickupSlot;
    final deliverySlot = state.deliverySlot;
    final address = state.address;
    if (!state.everyCategoryServiced ||
        tier == null ||
        pickupSlot == null ||
        deliverySlot == null ||
        address == null) {
      return;
    }
    emit(state.copyWith(submitting: true, failure: null));
    final result = await _createOrder(
      NewOrderParams(
        lines: [
          for (final category in state.selectedCategories)
            NewOrderLine(
              categoryId: category.id,
              subServiceId: state.subServiceByCategory[category.id]!.id,
            ),
        ],
        tierId: tier.id,
        pickupSlotId: pickupSlot.id,
        deliverySlotId: deliverySlot.id,
        addressId: address.id,
      ),
    );
    emit(
      result.fold(
        onErr: (f) => state.copyWith(submitting: false, failure: f),
        onOk: (order) => state.copyWith(submitting: false, created: order),
      ),
    );
  }
}
