import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/orders/domain/entities/laundry_order.dart';
import 'package:laundry_app/features/orders/domain/entities/order_line.dart';
import 'package:laundry_app/features/orders/domain/entities/order_rating.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/service_category.dart';
import 'package:laundry_app/features/orders/domain/entities/service_tier.dart';
import 'package:laundry_app/features/orders/domain/entities/sub_service.dart';
import 'package:laundry_app/features/orders/domain/entities/time_slot.dart';
import 'package:laundry_app/features/orders/domain/repositories/order_repository.dart';
import 'package:laundry_app/features/orders/domain/usecases/order_usecases.dart';
import 'package:laundry_app/features/orders/presentation/cubit/order_tracking_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrders extends Mock implements OrderRepository {}

LaundryOrder _order({
  OrderStatus status = OrderStatus.delivered,
  OrderRating? rating,
}) {
  final at = DateTime(2026, 9, 1, 9);
  final slot = TimeSlot(id: 's', start: at, end: at, isFull: false);
  return LaundryOrder(
    id: 'ord-1',
    number: 1,
    lines: const [
      OrderLine(
        category: ServiceCategory(id: 'c', name: 'Clothes', description: ''),
        subService: SubService(
          id: 's',
          categoryId: 'c',
          name: 'Wash',
          description: '',
        ),
      ),
    ],
    tier: const ServiceTier(
      id: 't',
      name: 'Standard',
      deliveryHours: 48,
      isVip: false,
      perks: [],
    ),
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
    status: status,
    createdAt: at,
    timeline: const [],
    rating: rating,
  );
}

void main() {
  group('LaundryOrder.canRate', () {
    test('only a delivered, unrated order can be rated', () {
      expect(_order().canRate, isTrue);
      expect(_order(status: OrderStatus.outForDelivery).canRate, isFalse);
      expect(_order(status: OrderStatus.cancelled).canRate, isFalse);
      expect(
        _order(rating: OrderRating(stars: 4, ratedAt: DateTime(2026))).canRate,
        isFalse,
      );
    });
  });

  group('OrderTrackingCubit.rate', () {
    late _MockOrders repo;

    setUp(() {
      repo = _MockOrders();
      when(() => repo.getOrder('ord-1')).thenAnswer((_) async => Ok(_order()));
    });

    OrderTrackingCubit build() => OrderTrackingCubit(
      'ord-1',
      GetOrder(repo),
      ChoosePaymentMethod(repo),
      RateOrder(repo),
    );

    test('sends the stars and note and shows the rated order', () async {
      final rated = _order(
        rating: OrderRating(
          stars: 5,
          comment: 'Crisp',
          ratedAt: DateTime(2026),
        ),
      );
      when(() => repo.rateOrder('ord-1', stars: 5, comment: 'Crisp'))
          .thenAnswer((_) async => Ok(rated));

      final cubit = build();
      await pumpEventQueue();
      await cubit.rate(5, comment: 'Crisp');

      expect(cubit.state.order, rated);
      expect(cubit.state.rating, isFalse);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a failed send keeps the order and reports the failure', () async {
      when(() => repo.rateOrder('ord-1', stars: 2))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      final cubit = build();
      await pumpEventQueue();
      await cubit.rate(2);

      expect(cubit.state.order, _order());
      expect(cubit.state.rating, isFalse);
      expect(cubit.state.failure, const NetworkFailure());
      await cubit.close();
    });
  });
}
