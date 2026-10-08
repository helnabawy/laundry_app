import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/push/push_service.dart';
import 'package:laundry_app/core/router/routes.dart';

void main() {
  group('tapping a push', () {
    Map<String, dynamic> order(String kind) => {
      'type': 'order',
      'kind': kind,
      'orderId': 'o1',
      'status': 'driverAssigned',
    };

    test('opens the order for a customer', () {
      expect(
        routeFor(order('driverAssigned'), isDriver: false),
        Routes.orderDetail('o1'),
      );
    });

    test('opens the task for a driver', () {
      expect(
        routeFor(order('newPickup'), isDriver: true),
        Routes.driverPickup('o1'),
      );
      expect(
        routeFor(order('newDelivery'), isDriver: true),
        Routes.driverDelivery('o1'),
      );
      expect(routeFor(order('cancelled'), isDriver: true), Routes.driverHome);
    });

    test('ignores pushes that are not about an order', () {
      expect(routeFor({'type': 'catalogue'}, isDriver: false), isNull);
      expect(routeFor({'type': 'order'}, isDriver: false), isNull);
    });
  });

  test("laundry topics match the server's names", () {
    expect(laundryTopic('fac-1'), 'vendor-fac-1');
    expect(laundryTopic('a b/c'), 'vendor-a_b_c');
  });
}
