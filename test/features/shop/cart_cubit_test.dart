import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/laundry_order.dart';
import 'package:laundry_app/features/orders/domain/entities/order_item.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/product.dart';
import 'package:laundry_app/features/orders/domain/entities/service_tier.dart';
import 'package:laundry_app/features/orders/domain/entities/time_slot.dart';
import 'package:laundry_app/features/shop/domain/entities/cart.dart';
import 'package:laundry_app/features/shop/domain/entities/cart_line.dart';
import 'package:laundry_app/features/shop/domain/repositories/cart_repository.dart';
import 'package:laundry_app/features/shop/domain/usecases/cart_usecases.dart';
import 'package:laundry_app/features/shop/presentation/cubit/cart_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockCartRepository extends Mock implements CartRepository {}

const _tshirt = Product(
  id: 'p-tshirt',
  categoryId: 'c-clothes',
  name: 'T-shirt',
  description: '',
  unitPrice: 2,
);
const _shirt = Product(
  id: 'p-shirt',
  categoryId: 'c-clothes',
  name: 'Shirt',
  description: '',
  unitPrice: 10,
);
const _vip = ServiceTier(
  id: 'tier-vip',
  name: 'VIP',
  deliveryHours: 24,
  isVip: true,
  perks: [],
  surchargeType: TierSurchargeType.percentage,
  surchargeValue: 15,
);
const _standard = ServiceTier(
  id: 'tier-standard',
  name: 'Standard',
  deliveryHours: 48,
  isVip: false,
  perks: [],
);

void main() {
  group('Cart', () {
    test('subtotal, vipSurcharge and total', () {
      const cart = Cart(
        lines: [
          CartLine(product: _tshirt, quantity: 3), // 6
          CartLine(product: _shirt, quantity: 2), // 20
        ],
        tier: _vip,
      );
      expect(cart.itemCount, 5);
      expect(cart.subtotal, 26);
      expect(cart.vipSurcharge, 26 * 0.15);
      expect(cart.total, 26 + 26 * 0.15);
    });

    test('a null/non-VIP tier adds no surcharge', () {
      const cart = Cart(lines: [CartLine(product: _tshirt, quantity: 1)]);
      expect(cart.vipSurcharge, 0);
      expect(cart.total, cart.subtotal);
    });

    test('withQuantity adds, updates and removes at zero', () {
      const cart = Cart();
      final withOne = cart.withQuantity(_tshirt, 1);
      expect(withOne.quantityOf(_tshirt.id), 1);

      final withThree = withOne.withQuantity(_tshirt, 3);
      expect(withThree.quantityOf(_tshirt.id), 3);
      expect(withThree.lines.length, 1);

      final removed = withThree.withQuantity(_tshirt, 0);
      expect(removed.isEmpty, isTrue);
      expect(removed.quantityOf(_tshirt.id), isNull);
    });
  });

  group('CartCubit', () {
    late _MockCartRepository repo;

    CartCubit build() =>
        CartCubit(LoadCart(repo), SaveCart(repo), ClearCart(repo));

    setUpAll(() => registerFallbackValue(const Cart()));

    setUp(() {
      repo = _MockCartRepository();
      when(repo.load).thenAnswer((_) async => const Ok(Cart()));
      when(() => repo.save(any())).thenAnswer((_) async => const Ok(null));
      when(repo.clear).thenAnswer((_) async => const Ok(null));
    });

    blocTest<CartCubit, Cart>(
      'add starts a line at the given quantity, then increments it',
      build: build,
      act: (cubit) {
        cubit.add(_tshirt);
        cubit.add(_tshirt, quantity: 2);
      },
      expect: () => [
        const Cart(lines: [CartLine(product: _tshirt, quantity: 1)]),
        const Cart(lines: [CartLine(product: _tshirt, quantity: 3)]),
      ],
      verify: (_) => verify(() => repo.save(any())).called(2),
    );

    blocTest<CartCubit, Cart>(
      'increment and decrement move the line by one',
      build: build,
      seed: () => const Cart(lines: [CartLine(product: _tshirt, quantity: 1)]),
      act: (cubit) {
        cubit.increment(_tshirt.id);
        cubit.decrement(_tshirt.id);
        cubit.decrement(_tshirt.id);
      },
      expect: () => [
        const Cart(lines: [CartLine(product: _tshirt, quantity: 2)]),
        const Cart(lines: [CartLine(product: _tshirt, quantity: 1)]),
        const Cart(),
      ],
    );

    blocTest<CartCubit, Cart>(
      'setQuantity replaces the line, remove drops it',
      build: build,
      seed: () => const Cart(lines: [CartLine(product: _tshirt, quantity: 1)]),
      act: (cubit) {
        cubit.setQuantity(_tshirt.id, 5);
        cubit.remove(_tshirt.id);
      },
      expect: () => [
        const Cart(lines: [CartLine(product: _tshirt, quantity: 5)]),
        const Cart(),
      ],
    );

    blocTest<CartCubit, Cart>(
      'setTier attaches the surcharge tier',
      build: build,
      seed: () => const Cart(lines: [CartLine(product: _shirt, quantity: 1)]),
      act: (cubit) => cubit.setTier(_vip),
      expect: () => [
        const Cart(lines: [CartLine(product: _shirt, quantity: 1)], tier: _vip),
      ],
    );

    blocTest<CartCubit, Cart>(
      'clear empties the cart and calls ClearCart',
      build: build,
      seed: () => const Cart(lines: [CartLine(product: _tshirt, quantity: 1)]),
      act: (cubit) => cubit.clear(),
      expect: () => [const Cart()],
      verify: (_) => verify(repo.clear).called(1),
    );

    blocTest<CartCubit, Cart>(
      'loadFrom repopulates the cart from a past shop-flow order, resolved '
      'against the live catalog',
      build: build,
      act: (cubit) => cubit.loadFrom(_pastOrder(), const [_tshirt, _shirt]),
      expect: () => [
        const Cart(
          lines: [
            CartLine(product: _tshirt, quantity: 2),
            CartLine(product: _shirt, quantity: 1),
          ],
          tier: _standard,
        ),
      ],
    );

    blocTest<CartCubit, Cart>(
      'loadFrom drops a line whose product is no longer in the catalog',
      build: build,
      act: (cubit) => cubit.loadFrom(_pastOrder(), const [_tshirt]),
      expect: () => [
        const Cart(
          lines: [CartLine(product: _tshirt, quantity: 2)],
          tier: _standard,
        ),
      ],
    );

    blocTest<CartCubit, Cart>(
      'init loads the persisted cart once',
      setUp: () => when(repo.load).thenAnswer(
        (_) async => const Ok(
          Cart(lines: [CartLine(product: _tshirt, quantity: 4)]),
        ),
      ),
      build: build,
      act: (cubit) => cubit.init(),
      expect: () => [
        const Cart(lines: [CartLine(product: _tshirt, quantity: 4)]),
      ],
      verify: (_) => verify(repo.load).called(1),
    );

    blocTest<CartCubit, Cart>(
      'init only reads persistence once, however many times it is called',
      build: build,
      act: (cubit) async {
        await cubit.init();
        await cubit.init();
      },
      verify: (_) => verify(repo.load).called(1),
    );
  });
}

LaundryOrder _pastOrder() {
  final at = DateTime(2026, 1, 1);
  final slot = TimeSlot(id: 's', start: at, end: at, isFull: false);
  return LaundryOrder(
    id: 'ord-1',
    number: 1042,
    lines: const [],
    invoice: const Invoice(
      id: 'inv-1',
      items: [
        OrderItem(
          productId: 'p-tshirt',
          categoryId: 'c-clothes',
          name: 'T-shirt',
          quantity: 2,
          unitPrice: 2,
        ),
        OrderItem(
          productId: 'p-shirt',
          categoryId: 'c-clothes',
          name: 'Shirt',
          quantity: 1,
          unitPrice: 10,
        ),
      ],
      paymentMethod: PaymentMethod.card,
      vipSurcharge: 0,
      paid: true,
    ),
    tier: _standard,
    pickupSlot: slot,
    deliverySlot: slot,
    address: const Address(
      id: 'a',
      city: 'Dubai',
      area: 'Marina',
      building: 'B',
      apartment: '1',
    ),
    customerName: 'Sara',
    customerPhone: '+971501234567',
    status: OrderStatus.delivered,
    createdAt: at,
    timeline: const [],
  );
}
