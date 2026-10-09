import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/network/api_client.dart';
import 'package:laundry_app/core/push/local_notifications.dart';
import 'package:laundry_app/core/push/push_service.dart';
import 'package:laundry_app/core/router/routes.dart';
import 'package:laundry_app/core/sync/refresh_bus.dart';

class _FakeLocalNotifications implements LocalNotifications {
  final shown = <({String title, String body, Map<String, dynamic> data})>[];

  @override
  Future<void> show({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async => shown.add((title: title, body: body, data: data));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const orderData = {
    'type': 'order',
    'kind': 'pickedUp',
    'orderId': 'o1',
    'status': 'pickedUp',
  };

  late _FakeLocalNotifications local;
  late RefreshBus bus;
  late PushService push;

  setUp(() {
    local = _FakeLocalNotifications();
    bus = RefreshBus();
    push = PushService(
      api: ApiClient(Dio()),
      refreshBus: bus,
      localNotifications: local,
    );
  });

  group('a push while the app is open', () {
    test('shows a notification and refreshes the order', () async {
      final signals = <RefreshSignal>[];
      bus.signals.listen(signals.add);

      await push.onForegroundMessage(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'Items collected',
            body: 'Order 12 is on its way to the laundry.',
          ),
          data: orderData,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(local.shown, hasLength(1));
      expect(local.shown.single.title, 'Items collected');
      expect(local.shown.single.data, orderData);
      expect(
        signals.whereType<OrderChanged>().map((s) => s.orderId),
        ['o1'],
      );
    });

    test('shows nothing for a silent catalogue ping', () async {
      await push.onForegroundMessage(
        const RemoteMessage(data: {'type': 'catalogue', 'vendorId': 'v1'}),
      );
      expect(local.shown, isEmpty);
    });
  });

  test('tapping a shown notification opens the order', () async {
    final routes = <String>[];
    push.openedRoutes.listen(routes.add);

    final data = decodePayload(
      // What LocalNotifications.show stores as the payload.
      '{"type":"order","kind":"pickedUp","orderId":"o1"}',
    );
    push.onTapped(data!);
    await Future<void>.delayed(Duration.zero);

    expect(routes, [Routes.orderDetail('o1')]);
  });

  group('notification payloads', () {
    test('ignore what is not push data', () {
      expect(decodePayload(null), isNull);
      expect(decodePayload(''), isNull);
      expect(decodePayload('not json'), isNull);
      expect(decodePayload('[1]'), isNull);
    });

    test('share one notification per order', () {
      expect(
        notificationId({...orderData, 'kind': 'invoiceReady'}),
        notificationId(orderData),
      );
      expect(
        notificationId({...orderData, 'orderId': 'o2'}),
        isNot(notificationId(orderData)),
      );
    });
  });
}
