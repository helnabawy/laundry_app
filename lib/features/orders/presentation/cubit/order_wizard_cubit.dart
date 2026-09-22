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
  }) : _getCategories = getCategories,
       _getSubServices = getSubServices,
       _getTiers = getTiers,
       _getPickupSlots = getPickupSlots,
       _getDeliverySlots = getDeliverySlots,
       _getAddresses = getAddresses,
       _createOrder = createOrder,
       super(OrderWizardState()) {
    _loadCategories();
  }

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
