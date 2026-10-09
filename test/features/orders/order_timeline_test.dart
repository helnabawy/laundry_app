import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/features/orders/data/models/laundry_order_model.dart';
import 'package:laundry_app/features/orders/domain/entities/laundry_order.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/presentation/widgets/order_timeline.dart';

void main() {
  const wizard = [
    OrderStatus.driverAssigned,
    OrderStatus.pickedUp,
    OrderStatus.atFacility,
    OrderStatus.processing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  LaundryOrder order(String status, List<String> reached) {
    final json = jsonDecode(
      File('test/fixtures/api/order_other_laundry.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    var minute = 0;
    return LaundryOrderModel.fromJson({
      ...json,
      'status': status,
      'timeline': [
        for (final s in ['pending', ...reached])
          {
            'status': s,
            'at': DateTime.utc(2026, 10, 9, 9, minute++).toIso8601String(),
          },
      ],
    });
  }

  test('awaiting payment: the order is still at the laundry', () {
    final o = order('awaitingPayment', [
      'driverAssigned',
      'pickedUp',
      'atFacility',
      'awaitingPayment',
    ]);
    expect(reachedMilestone(o, wizard), wizard.indexOf(OrderStatus.atFacility));
  });

  test('a milestone status is its own step', () {
    final o = order('pickedUp', ['driverAssigned', 'pickedUp']);
    expect(reachedMilestone(o, wizard), 1);
  });

  test('just placed: nothing reached yet', () {
    expect(reachedMilestone(order('pending', []), wizard), -1);
  });

  test('a failed delivery stays at the step it failed after', () {
    final o = order('deliveryFailed', [
      'driverAssigned',
      'pickedUp',
      'atFacility',
      'awaitingPayment',
      'processing',
      'outForDelivery',
      'deliveryFailed',
    ]);
    expect(
      reachedMilestone(o, wizard),
      wizard.indexOf(OrderStatus.outForDelivery),
    );
  });
}
