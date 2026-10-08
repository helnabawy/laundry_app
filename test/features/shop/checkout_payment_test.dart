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
import 'package:laundry_app/features/orders/domain/entities/payment_info.dart';
import 'package:laundry_app/features/orders/domain/entities/product.dart';
import 'package:laundry_app/features/orders/domain/entities/service_tier.dart';
import 'package:laundry_app/features/orders/domain/entities/time_slot.dart';
import 'package:laundry_app/features/orders/domain/repositories/catalog_repository.dart';
import 'package:laundry_app/features/orders/domain/repositories/order_repository.dart';
import 'package:laundry_app/features/orders/domain/repositories/payment_repository.dart';
import 'package:laundry_app/features/orders/domain/usecases/catalog_usecases.dart';
import 'package:laundry_app/features/orders/domain/usecases/order_usecases.dart';
import 'package:laundry_app/features/orders/domain/usecases/payment_usecases.dart';
import 'package:laundry_app/features/shop/domain/entities/cart.dart';
import 'package:laundry_app/features/shop/domain/repositories/cart_repository.dart';
import 'package:laundry_app/features/shop/domain/usecases/cart_usecases.dart';
import 'package:laundry_app/features/shop/presentation/cubit/cart_cubit.dart';
import 'package:laundry_app/features/shop/presentation/cubit/checkout_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalog extends Mock implements CatalogRepository {}

class _MockAddresses extends Mock implements AddressRepository {}

class _MockOrders extends Mock implements OrderRepository {}

class _MockPayments extends Mock implements PaymentRepository {}

class _MockCartRepository extends Mock implements CartRepository {}

const _suit = Product(
  id: 'p-suit',
  categoryId: 'cat-clothes',
  name: 'Suit',
  description: '',
  unitPrice: 45,
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

const _options = [
  PaymentOption(
    method: PaymentMethod.card,
    provider: PaymentProvider.networkIntl,
  ),
  PaymentOption(
    method: PaymentMethod.payLater,
    provider: PaymentProvider.tabby,
    minAmount: 50,
    maxAmount: 5000,
    installments: 4,
  ),
  PaymentOption(
    method: PaymentMethod.cashOnDelivery,
    provider: PaymentProvider.cash,
    fee: 5,
  ),
];

PaymentInfo _payment(String id, PaymentStatus status) => PaymentInfo(
  id: id,
  status: status,
  provider: PaymentProvider.tabby,
  method: PaymentMethod.payLater,
  amount: 90,
  checkoutUrl: status == PaymentStatus.pending ? 'http://x/pay/$id' : null,
  paidAt: status == PaymentStatus.succeeded ? DateTime(2026, 10, 9) : null,
);

TimeSlot _slot(DateTime day, int hour) => TimeSlot(
  id: '${day.toIso8601String()}-$hour',
  start: DateTime(day.year, day.month, day.day, hour),
  end: DateTime(day.year, day.month, day.day, hour + 2),
  isFull: false,
);

LaundryOrder _placed(PaymentInfo payment) {
  final now = DateTime(2026, 10, 9);
  return LaundryOrder(
    id: 'ord-1050',
    number: 1050,
    lines: const [],
    invoice: Invoice(
      id: 'INV-1050',
      items: const [
        OrderItem(
          productId: 'p-suit',
          name: 'Suit',
          quantity: 2,
          unitPrice: 45,
        ),
      ],
      paymentMethod: PaymentMethod.payLater,
      paid: false,
      payment: payment,
    ),
    tier: _standard,
    pickupSlot: _slot(now, 9),
    deliverySlot: _slot(now, 17),
    address: _home,
    customerName: 'Sara',
    customerPhone: '+971501234567',
    status: OrderStatus.pending,
    createdAt: now,
    timeline: const [],
  );
}

void main() {
  late _MockCatalog catalog;
  late _MockAddresses addresses;
  late _MockOrders orders;
  late _MockPayments payments;
  late _MockCartRepository cartRepo;
  late CartCubit cart;

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
    payments = _MockPayments();
    cartRepo = _MockCartRepository();
    when(cartRepo.load).thenAnswer((_) async => const Ok(Cart()));
    when(() => cartRepo.save(any())).thenAnswer((_) async => const Ok(null));
    when(cartRepo.clear).thenAnswer((_) async => const Ok(null));
    cart = CartCubit(
      LoadCart(cartRepo),
      SaveCart(cartRepo),
      ClearCart(cartRepo),
    );

    final tomorrow = DateUtils.addDaysToDate(
      DateUtils.dateOnly(DateTime.now()),
      1,
    );
    when(catalog.getTiers).thenAnswer((_) async => const Ok([_standard]));
    when(addresses.getAddresses).thenAnswer((_) async => const Ok([_home]));
    when(() => catalog.getPickupSlots(any(), any()))
        .thenAnswer((_) async => Ok([_slot(tomorrow, 9)]));
    when(
      () => catalog.getDeliverySlots(
        any(),
        any(),
        notBefore: any(named: 'notBefore'),
      ),
    ).thenAnswer((inv) async {
      final day = inv.positionalArguments.first as DateTime;
      return Ok([_slot(day, 17)]);
    });
    when(payments.getPaymentOptions)
        .thenAnswer((_) async => const Ok(_options));
  });

  CheckoutCubit build() => CheckoutCubit(
    cart: cart,
    getProducts: GetProducts(catalog),
    getTiers: GetServiceTiers(catalog),
    getPickupSlots: GetPickupSlots(catalog),
    getDeliverySlots: GetDeliverySlots(catalog),
    getAddresses: GetAddresses(addresses),
    createOrder: CreateOrder(orders),
    getPaymentOptions: GetPaymentOptions(payments),
    retryPayment: RetryPayment(payments),
  );

  /// Fills the cart, picks pay-later and places the order.
  Future<CheckoutCubit> placeWithPayLater(PaymentInfo payment) async {
    when(() => orders.createOrder(any()))
        .thenAnswer((_) async => Ok(_placed(payment)));
    cart.add(_suit, quantity: 2); // AED 90
    final cubit = build();
    await pumpEventQueue();
    cubit.selectPaymentMethod(PaymentMethod.payLater);
    expect(cubit.state.paymentMethod, PaymentMethod.payLater);
    await cubit.nextStep();
    await pumpEventQueue();
    await cubit.selectPickupSlot(cubit.state.pickupSlots.first);
    cubit.selectDeliverySlot(cubit.state.deliverySlots.first);
    await cubit.nextStep();
    return cubit;
  }

  test('pay-later is offered only within its limits', () async {
    cart.add(_suit); // AED 45 — under tabby's AED 50 minimum
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.payLaterOption, isNotNull);
    expect(cubit.accepts(PaymentMethod.payLater), isFalse);
    cubit.selectPaymentMethod(PaymentMethod.payLater);
    expect(cubit.state.paymentMethod, PaymentMethod.card);

    cart.add(_suit); // AED 90
    expect(cubit.accepts(PaymentMethod.payLater), isTrue);
    await cubit.close();
  });

  test(
    'an order placed with pay-later starts with a pending checkout',
    () async {
      final cubit = await placeWithPayLater(
        _payment('pay-1', PaymentStatus.pending),
      );
      final params =
          verify(() => orders.createOrder(captureAny())).captured.single
              as NewOrderParams;
      expect(params.paymentMethod, PaymentMethod.payLater);
      final invoice = cubit.state.created!.invoice!;
      expect(invoice.awaitingOnlinePayment, isTrue);
      expect(invoice.payment!.isPending, isTrue);
      await cubit.close();
    },
  );

  test('a successful checkout marks the placed order paid', () async {
    final cubit = await placeWithPayLater(
      _payment('pay-1', PaymentStatus.pending),
    );
    cubit.paymentSettled(_payment('pay-1', PaymentStatus.succeeded));
    final invoice = cubit.state.created!.invoice!;
    expect(invoice.paid, isTrue);
    expect(invoice.paidAt, DateTime(2026, 10, 9));
    expect(invoice.awaitingOnlinePayment, isFalse);
    await cubit.close();
  });

  test('a declined checkout stays unpaid and can be retried', () async {
    final cubit = await placeWithPayLater(
      _payment('pay-1', PaymentStatus.pending),
    );
    cubit.paymentSettled(_payment('pay-1', PaymentStatus.failed));
    expect(cubit.state.created!.invoice!.paid, isFalse);
    expect(cubit.state.created!.invoice!.payment!.status, PaymentStatus.failed);

    when(() => payments.retryPayment('ord-1050', method: any(named: 'method')))
        .thenAnswer(
          (_) async => Ok(_placed(_payment('pay-2', PaymentStatus.pending))),
        );
    final next = await cubit.retryPayment();
    expect(next!.id, 'pay-2');
    expect(cubit.state.created!.invoice!.payment!.id, 'pay-2');

    when(() => payments.retryPayment('ord-1050', method: any(named: 'method')))
        .thenAnswer(
          (_) async =>
              const Err(ServerFailure(message: 'This order is already paid')),
        );
    expect(await cubit.retryPayment(), isNull);
    expect(cubit.state.failure, isNotNull);
    await cubit.close();
  });
}
