import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/addresses/domain/repositories/address_repository.dart';
import 'package:laundry_app/features/addresses/domain/usecases/get_addresses.dart';
import 'package:laundry_app/features/orders/domain/entities/laundry_order.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/order_line.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/service_category.dart';
import 'package:laundry_app/features/orders/domain/entities/service_tier.dart';
import 'package:laundry_app/features/orders/domain/entities/sub_service.dart';
import 'package:laundry_app/features/orders/domain/entities/time_slot.dart';
import 'package:laundry_app/features/orders/domain/repositories/catalog_repository.dart';
import 'package:laundry_app/features/orders/domain/repositories/order_repository.dart';
import 'package:laundry_app/features/orders/domain/usecases/catalog_usecases.dart';
import 'package:laundry_app/features/orders/domain/usecases/order_usecases.dart';
import 'package:laundry_app/features/orders/presentation/cubit/order_wizard_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalog extends Mock implements CatalogRepository {}

class _MockAddresses extends Mock implements AddressRepository {}

class _MockOrders extends Mock implements OrderRepository {}

const _window = Duration(milliseconds: 20);

/// For tests that act inside the window: long enough never to run out
/// mid-test on a slow machine.
const _held = Duration(hours: 1);

const _clothes = ServiceCategory(
  id: 'cat-clothes',
  name: 'Clothes',
  description: '',
);
const _curtains = ServiceCategory(
  id: 'cat-curtains',
  name: 'Curtains',
  description: '',
);
const _washIron = SubService(
  id: 'sub-wash-iron',
  categoryId: 'cat-clothes',
  name: 'Wash & Iron',
  description: '',
);
const _curtainClean = SubService(
  id: 'sub-curtain-clean',
  categoryId: 'cat-curtains',
  name: 'Clean',
  description: '',
);
const _standard = ServiceTier(
  id: 'tier-standard',
  name: 'Standard',
  deliveryHours: 48,
  isVip: false,
  perks: [],
);
const _home = Address(
  id: 'adr-1',
  city: 'Dubai',
  area: 'Marina',
  building: 'B1',
  apartment: '101',
);
const _work = Address(
  id: 'adr-2',
  city: 'Dubai',
  area: 'DIFC',
  building: 'Gate',
  apartment: '5',
  kind: AddressKind.work,
);

TimeSlot _slot(DateTime day, int startHour, {bool full = false}) => TimeSlot(
  id: '${day.toIso8601String()}-$startHour',
  start: DateTime(day.year, day.month, day.day, startHour),
  end: DateTime(day.year, day.month, day.day, startHour + 2),
  isFull: full,
);

LaundryOrder _pastOrder() {
  final then = DateTime(2026, 1, 1);
  return LaundryOrder(
    id: 'ord-1042',
    number: 1042,
    lines: const [
      OrderLine(category: _clothes, subService: _washIron),
      OrderLine(category: _curtains, subService: _curtainClean),
    ],
    tier: _standard,
    pickupSlot: _slot(then, 9),
    deliverySlot: _slot(then, 17),
    address: _work,
    customerName: 'Sara',
    customerPhone: '+971501234567',
    status: OrderStatus.delivered,
    createdAt: then,
    timeline: const [],
  );
}

void main() {
  late _MockCatalog catalog;
  late _MockAddresses addresses;
  late _MockOrders orders;
  late DateTime today;
  late DateTime tomorrow;

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(
      const NewOrderParams(
        lines: [],
        tierId: '',
        pickupSlotId: '',
        deliverySlotId: '',
        addressId: '',
      ),
    );
  });

  setUp(() {
    catalog = _MockCatalog();
    addresses = _MockAddresses();
    orders = _MockOrders();
    when(() => orders.createOrder(any()))
        .thenAnswer((_) async => Ok(_pastOrder()));
    today = DateUtils.dateOnly(DateTime.now());
    tomorrow = DateUtils.addDaysToDate(today, 1);

    when(catalog.getCategories)
        .thenAnswer((_) async => const Ok([_clothes, _curtains]));
    when(() => catalog.getSubServices('cat-clothes'))
        .thenAnswer((_) async => const Ok([_washIron]));
    when(() => catalog.getSubServices('cat-curtains'))
        .thenAnswer((_) async => const Ok([_curtainClean]));
    when(catalog.getTiers).thenAnswer((_) async => const Ok([_standard]));
    when(addresses.getAddresses)
        .thenAnswer((_) async => const Ok([_home, _work]));

    // Nothing open today; tomorrow's first window is full, the second open.
    when(() => catalog.getPickupSlots(any(), any())).thenAnswer((inv) async {
      final day = inv.positionalArguments.first as DateTime;
      return Ok(
        DateUtils.isSameDay(day, tomorrow)
            ? [_slot(day, 9, full: true), _slot(day, 11)]
            : <TimeSlot>[],
      );
    });
    // The first day the level allows has nothing open; the day after does.
    when(
      () => catalog.getDeliverySlots(
        any(),
        any(),
        notBefore: any(named: 'notBefore'),
      ),
    ).thenAnswer((inv) async {
      final day = inv.positionalArguments.first as DateTime;
      final notBefore = inv.namedArguments[#notBefore] as DateTime;
      final firstDay = DateUtils.dateOnly(notBefore);
      return Ok(day.isAfter(firstDay) ? [_slot(day, 13)] : <TimeSlot>[]);
    });
  });

  OrderWizardCubit build({
    LaundryOrder? reorderFrom,
    String? startWithCategory,
    Duration undoWindow = _window,
  }) => OrderWizardCubit(
    getCategories: GetServiceCategories(catalog),
    getSubServices: GetSubServices(catalog),
    getTiers: GetServiceTiers(catalog),
    getPickupSlots: GetPickupSlots(catalog),
    getDeliverySlots: GetDeliverySlots(catalog),
    getAddresses: GetAddresses(addresses),
    createOrder: CreateOrder(orders),
    reorderFrom: reorderFrom,
    startWithCategory: startWithCategory,
    undoWindow: undoWindow,
  );

  Future<OrderWizardState> settle(OrderWizardCubit cubit) async {
    // Every load in the prefill resolves on the microtask queue.
    await pumpEventQueue();
    return cubit.state;
  }

  /// Lets the undo window run out.
  Future<OrderWizardState> outlast(OrderWizardCubit cubit) async {
    await Future<void>.delayed(_window * 3);
    return settle(cubit);
  }

  test(
    'reorder places the order in one tap, in the soonest open windows',
    () async {
      final cubit = build(reorderFrom: _pastOrder());
      expect(cubit.state.reorderStage, ReorderStage.preparing);
      var state = await settle(cubit);

      expect(state.reorderStage, ReorderStage.countdown);
      verifyNever(() => orders.createOrder(any()));

      state = await outlast(cubit);
      expect(state.reorderStage, isNull);
      expect(state.created, isNotNull);

      expect(state.reorderOf, 1042);
      expect(state.step, 4);
      expect(state.selectedCategories, [_clothes, _curtains]);
      expect(state.subServiceByCategory, {
        'cat-clothes': _washIron,
        'cat-curtains': _curtainClean,
      });
      expect(state.tier, _standard);
      expect(
        state.address,
        _work,
        reason: 'the past order\'s address, not the first',
      );

      expect(state.pickupDay, tomorrow);
      expect(state.pickupSlot, _slot(tomorrow, 11));

      final pickupStart = state.pickupSlot!.start;
      final firstAllowed = DateUtils.dateOnly(
        pickupStart.add(const Duration(hours: 48)),
      );
      final expectedDay = DateUtils.addDaysToDate(firstAllowed, 1);
      expect(state.deliveryDay, expectedDay);
      expect(state.deliverySlot, _slot(expectedDay, 13));

      final sent =
          verify(() => orders.createOrder(captureAny())).captured.single
              as NewOrderParams;
      expect(sent.lines, const [
        NewOrderLine(categoryId: 'cat-clothes', subServiceId: 'sub-wash-iron'),
        NewOrderLine(
          categoryId: 'cat-curtains',
          subServiceId: 'sub-curtain-clean',
        ),
      ]);
      expect(sent.tierId, 'tier-standard');
      expect(sent.addressId, 'adr-2');
      expect(sent.pickupSlotId, _slot(tomorrow, 11).id);
      expect(sent.deliverySlotId, _slot(expectedDay, 13).id);

      await cubit.close();
    },
  );

  test('with no open window, reorder waits on the schedule step', () async {
    when(() => catalog.getPickupSlots(any(), any()))
        .thenAnswer((_) async => const Ok(<TimeSlot>[]));

    final cubit = build(reorderFrom: _pastOrder());
    final state = await outlast(cubit);

    expect(state.reorderStage, isNull);
    expect(state.step, 4);
    expect(state.pickupSlot, isNull);
    expect(state.created, isNull);
    verifyNever(() => orders.createOrder(any()));

    await cubit.close();
  });

  test('a refused reorder leaves the filled schedule to confirm', () async {
    when(() => orders.createOrder(any()))
        .thenAnswer((_) async => const Err(NetworkFailure()));

    final cubit = build(reorderFrom: _pastOrder());
    final state = await outlast(cubit);

    expect(state.reorderStage, isNull);
    expect(state.step, 4);
    expect(state.created, isNull);
    expect(state.failure, const NetworkFailure());
    expect(state.canGoNext, isTrue, reason: 'one tap on Confirm retries');

    await cubit.close();
  });

  test('undo within the window sends nothing', () async {
    final cubit = build(reorderFrom: _pastOrder(), undoWindow: _held);
    await settle(cubit);
    cubit.undoReorder();
    final state = await outlast(cubit);

    expect(state.reorderStage, ReorderStage.undone);
    expect(state.created, isNull);
    verifyNever(() => orders.createOrder(any()));

    await cubit.close();
  });

  test('undo while still preparing sends nothing either', () async {
    final cubit = build(reorderFrom: _pastOrder(), undoWindow: _held)
      ..undoReorder();
    final state = await outlast(cubit);

    expect(state.reorderStage, ReorderStage.undone);
    verifyNever(() => orders.createOrder(any()));

    await cubit.close();
  });

  test('changing the times stops the count on the filled schedule', () async {
    final cubit = build(reorderFrom: _pastOrder(), undoWindow: _held);
    await settle(cubit);
    cubit.editReorder();
    final state = await outlast(cubit);

    expect(state.reorderStage, isNull);
    expect(state.step, 4);
    expect(state.pickupSlot, _slot(tomorrow, 11));
    expect(state.canGoNext, isTrue);
    verifyNever(() => orders.createOrder(any()));

    await cubit.close();
  });

  test('a closed page never sends the held order', () async {
    final cubit = build(reorderFrom: _pastOrder(), undoWindow: _held);
    await settle(cubit);
    await cubit.close();
    await Future<void>.delayed(_window * 3);

    verifyNever(() => orders.createOrder(any()));
  });

  test(
    'reorder stops on the service step when a service is withdrawn',
    () async {
      when(() => catalog.getSubServices('cat-curtains'))
          .thenAnswer((_) async => const Ok(<SubService>[]));

      final cubit = build(reorderFrom: _pastOrder());
      final state = await settle(cubit);

      expect(state.step, 2);
      expect(state.selectedCategories, [_clothes, _curtains]);
      expect(state.subServiceByCategory, {'cat-clothes': _washIron});
      expect(state.pickupSlot, isNull);
      verifyNever(() => catalog.getPickupSlots(any(), any()));
      expect(state.reorderStage, isNull);
      verifyNever(() => orders.createOrder(any()));

      await cubit.close();
    },
  );

  test('reorder starts over when a category is no longer offered', () async {
    when(catalog.getCategories).thenAnswer((_) async => const Ok([_clothes]));

    final cubit = build(reorderFrom: _pastOrder());
    final state = await settle(cubit);

    expect(state.step, 1);
    expect(state.selectedCategories, [_clothes]);

    await cubit.close();
  });

  test('a fresh order opens on the first step with nothing chosen', () async {
    final cubit = build();
    final state = await settle(cubit);

    expect(state.reorderOf, isNull);
    expect(state.step, 1);
    expect(state.selectedCategories, isEmpty);
    verifyNever(catalog.getTiers);

    await cubit.close();
  });

  test('a category tapped on Home opens on step 2 with it chosen', () async {
    final cubit = build(startWithCategory: 'cat-curtains');
    expect(cubit.state.step, 2);
    final state = await settle(cubit);

    expect(state.step, 2);
    expect(state.selectedCategories, [_curtains]);
    expect(state.subServicesByCategory.keys, ['cat-curtains']);
    expect(state.loadingSubServices, isFalse);

    // Back lands on the full list with the choice kept, to add another.
    cubit.previousStep();
    expect(cubit.state.step, 1);
    expect(cubit.state.isSelected(_curtains), isTrue);
    expect(cubit.state.categories, isNotEmpty);
    await cubit.close();
  });

  test('an unknown category falls back to the category step', () async {
    final cubit = build(startWithCategory: 'cat-gone');
    final state = await settle(cubit);

    expect(state.step, 1);
    expect(state.selectedCategories, isEmpty);
    expect(state.loadingSubServices, isFalse);
    await cubit.close();
  });
}
