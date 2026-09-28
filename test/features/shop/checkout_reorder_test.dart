import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/addresses/domain/repositories/address_repository.dart';
import 'package:laundry_app/features/addresses/domain/usecases/get_addresses.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/laundry_order.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/order_item.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/product.dart';
import 'package:laundry_app/features/orders/domain/entities/service_tier.dart';
import 'package:laundry_app/features/orders/domain/entities/time_slot.dart';
import 'package:laundry_app/features/orders/domain/repositories/catalog_repository.dart';
import 'package:laundry_app/features/orders/domain/repositories/order_repository.dart';
import 'package:laundry_app/features/orders/domain/usecases/catalog_usecases.dart';
import 'package:laundry_app/features/orders/domain/usecases/order_usecases.dart';
import 'package:laundry_app/features/shop/domain/entities/cart.dart';
import 'package:laundry_app/features/shop/domain/entities/cart_line.dart';
import 'package:laundry_app/features/shop/domain/repositories/cart_repository.dart';
import 'package:laundry_app/features/shop/domain/usecases/cart_usecases.dart';
import 'package:laundry_app/features/shop/presentation/cubit/cart_cubit.dart';
import 'package:laundry_app/features/shop/presentation/cubit/checkout_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalog extends Mock implements CatalogRepository {}

class _MockAddresses extends Mock implements AddressRepository {}

class _MockOrders extends Mock implements OrderRepository {}

class _MockCartRepository extends Mock implements CartRepository {}

const _window = Duration(milliseconds: 20);

/// For tests that act inside the window: long enough never to run out
/// mid-test on a slow machine.
const _held = Duration(hours: 1);

const _tshirt = Product(
  id: 'p-tshirt',
  categoryId: 'cat-clothes',
  name: 'T-shirt',
  description: '',
  unitPrice: 2,
);
const _curtainPanel = Product(
  id: 'p-curtain',
  categoryId: 'cat-curtains',
  name: 'Curtain panel',
  description: '',
  unitPrice: 30,
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

/// A past shop-flow order (`lines` empty, `invoice` already populated).
LaundryOrder _pastOrder() {
  final then = DateTime(2026, 1, 1);
  return LaundryOrder(
    id: 'ord-1042',
    number: 1042,
    lines: const [],
    invoice: const Invoice(
      id: 'inv-1042',
      items: [
        OrderItem(
          productId: 'p-tshirt',
          categoryId: 'cat-clothes',
          name: 'T-shirt',
          quantity: 2,
          unitPrice: 2,
        ),
        OrderItem(
          productId: 'p-curtain',
          categoryId: 'cat-curtains',
          name: 'Curtain panel',
          quantity: 1,
          unitPrice: 30,
        ),
      ],
      paymentMethod: PaymentMethod.card,
      vipSurcharge: 0,
      paid: true,
    ),
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
  late _MockCartRepository cartRepo;
  late CartCubit cart;
  late DateTime today;
  late DateTime tomorrow;

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(
      const NewOrderParams(
        tierId: '',
        pickupSlotId: '',
        deliverySlotId: '',
        addressId: '',
      ),
    );
    registerFallbackValue(const Cart());
  });

  setUp(() {
    catalog = _MockCatalog();
    addresses = _MockAddresses();
    orders = _MockOrders();
    cartRepo = _MockCartRepository();
    when(cartRepo.load).thenAnswer((_) async => const Ok(Cart()));
    when(() => cartRepo.save(any())).thenAnswer((_) async => const Ok(null));
    when(cartRepo.clear).thenAnswer((_) async => const Ok(null));
    cart = CartCubit(LoadCart(cartRepo), SaveCart(cartRepo), ClearCart(cartRepo));

    when(() => orders.createOrder(any()))
        .thenAnswer((_) async => Ok(_pastOrder()));
    today = DateUtils.dateOnly(DateTime.now());
    tomorrow = DateUtils.addDaysToDate(today, 1);

    when(catalog.getProducts)
        .thenAnswer((_) async => const Ok([_tshirt, _curtainPanel]));
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

  CheckoutCubit build({
    LaundryOrder? reorderFrom,
    Duration undoWindow = _window,
  }) => CheckoutCubit(
    cart: cart,
    getProducts: GetProducts(catalog),
    getTiers: GetServiceTiers(catalog),
    getPickupSlots: GetPickupSlots(catalog),
    getDeliverySlots: GetDeliverySlots(catalog),
    getAddresses: GetAddresses(addresses),
    createOrder: CreateOrder(orders),
    reorderFrom: reorderFrom,
    undoWindow: undoWindow,
  );

  Future<CheckoutState> settle(CheckoutCubit cubit) async {
    // Every load in the prefill resolves on the microtask queue.
    await pumpEventQueue();
    return cubit.state;
  }

  /// Lets the undo window run out.
  Future<CheckoutState> outlast(CheckoutCubit cubit) async {
    await Future<void>.delayed(_window * 3);
    return settle(cubit);
  }

  test(
    'reorder repopulates the cart and places the order in the soonest '
    'open windows',
    () async {
      final cubit = build(reorderFrom: _pastOrder());
      expect(cubit.state.reorderStage, ReorderStage.preparing);
      var state = await settle(cubit);

      expect(state.reorderStage, ReorderStage.countdown);
      verifyNever(() => orders.createOrder(any()));

      // The cart is repopulated from the past order, resolved against the
      // live catalog.
      expect(cart.state.lines, const [
        CartLine(product: _tshirt, quantity: 2),
        CartLine(product: _curtainPanel, quantity: 1),
      ]);
      expect(cart.state.tier, _standard);

      state = await outlast(cubit);
      expect(state.reorderStage, isNull);
      expect(state.created, isNotNull);

      expect(state.reorderOf, 1042);
      expect(state.step, 2);
      expect(
        state.address,
        _work,
        reason: "the past order's address, not the first",
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
      expect(sent.items, const [
        NewOrderItem(productId: 'p-tshirt', quantity: 2),
        NewOrderItem(productId: 'p-curtain', quantity: 1),
      ]);
      expect(sent.lines, isEmpty);
      expect(sent.tierId, 'tier-standard');
      expect(sent.paymentMethod, PaymentMethod.card);
      expect(sent.addressId, 'adr-2');
      expect(sent.pickupSlotId, _slot(tomorrow, 11).id);
      expect(sent.deliverySlotId, _slot(expectedDay, 13).id);

      // A successful submit clears the cart.
      expect(cart.state.isEmpty, isTrue);

      await cubit.close();
    },
  );

  test('with no open window, reorder waits on the schedule step', () async {
    when(() => catalog.getPickupSlots(any(), any()))
        .thenAnswer((_) async => const Ok(<TimeSlot>[]));

    final cubit = build(reorderFrom: _pastOrder());
    final state = await outlast(cubit);

    expect(state.reorderStage, isNull);
    expect(state.step, 2);
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
    expect(state.step, 2);
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
    expect(state.step, 2);
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
    'a discontinued product silently drops from the reordered cart',
    () async {
      when(catalog.getProducts).thenAnswer((_) async => const Ok([_tshirt]));

      final cubit = build(reorderFrom: _pastOrder());
      final state = await settle(cubit);

      expect(cart.state.lines, const [
        CartLine(product: _tshirt, quantity: 2),
      ]);
      // The cart still has something in it, so checkout proceeds.
      expect(state.step, 2);

      await cubit.close();
    },
  );

  test(
    'reorder starts fresh when nothing in the past order is still offered',
    () async {
      when(catalog.getProducts).thenAnswer((_) async => const Ok(<Product>[]));

      final cubit = build(reorderFrom: _pastOrder());
      final state = await settle(cubit);

      expect(cart.state.isEmpty, isTrue);
      expect(state.step, 1);
      expect(state.reorderStage, isNull);

      await cubit.close();
    },
  );

  test('a fresh checkout opens on the first step with tiers loaded', () async {
    final cubit = build();
    final state = await settle(cubit);

    expect(state.reorderOf, isNull);
    expect(state.step, 1);
    expect(state.tiers, [_standard]);

    await cubit.close();
  });
}
