@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/exceptions.dart';
import 'package:laundry_app/core/network/api_client.dart';
import 'package:laundry_app/core/network/api_endpoints.dart';
import 'package:laundry_app/core/network/dio_factory.dart';
import 'package:laundry_app/core/storage/token_storage.dart';
import 'package:laundry_app/features/addresses/data/datasources/address_remote_data_source.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/laundries/data/datasources/laundry_remote_data_source.dart';
import 'package:laundry_app/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:laundry_app/features/notifications/domain/entities/app_notification.dart';
import 'package:laundry_app/features/orders/data/datasources/catalog_api_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/driver_task_api_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/order_api_data_source.dart';
import 'package:laundry_app/features/orders/data/datasources/payment_api_data_source.dart';
import 'package:laundry_app/features/orders/domain/entities/driver_task.dart';
import 'package:laundry_app/features/orders/domain/entities/invoice.dart';
import 'package:laundry_app/features/orders/domain/entities/laundry_order.dart';
import 'package:laundry_app/features/orders/domain/entities/new_order_params.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/orders/domain/entities/payment_info.dart';
import 'package:laundry_app/features/orders/domain/entities/task_failure.dart';
import 'package:laundry_app/features/support/data/datasources/support_remote_data_source.dart';
import 'package:laundry_app/features/support/domain/entities/support_message.dart';

/// Drives the app's real API data sources (the exact code the app runs with
/// `USE_MOCK_API=false`) against a running laundry_admin backend, through
/// every endpoint and the full order lifecycle. The laundry's steps run via
/// laundry_admin's `pnpm staff` CLI, the same services the portal calls.
///
/// Needs: laundry_admin dev server + seeded database. Run:
///   LAUNDRY_API_URL=http://localhost:3000 flutter test test/api_live
/// Skipped when LAUNDRY_API_URL is unset, so the normal suite stays offline.
void main() {
  final baseUrl = Platform.environment['LAUNDRY_API_URL'];
  final skip = baseUrl == null
      ? 'Set LAUNDRY_API_URL to run the live API tests'
      : null;
  final adminDir =
      Platform.environment['LAUNDRY_ADMIN_DIR'] ?? '../laundry_admin';

  const customerPhone = '+971501234567';
  const driverPhone = '+971500000001';
  const driverId = 'usr-driver-1';

  /// One app session: token storage + Dio + ApiClient, as the app wires them.
  ({ApiClient api, _MemoryTokens tokens, List<int> unauthorized}) session({
    String lang = 'en',
    String? laundryId,
  }) {
    final tokens = _MemoryTokens();
    final unauthorized = <int>[];
    final dio = createDio(
      baseUrl: baseUrl ?? '',
      tokenStorage: tokens,
      languageCode: () => lang,
      onUnauthorized: () => unauthorized.add(1),
      laundryId: () => laundryId,
    );
    return (api: ApiClient(dio), tokens: tokens, unauthorized: unauthorized);
  }

  Future<AppUser> signIn(
    ({ApiClient api, _MemoryTokens tokens, List<int> unauthorized}) s,
    String phone,
  ) async {
    final auth = AuthApiDataSource(s.api);
    await auth.requestOtp(phone);
    final res = await auth.verifyOtp(phone, '1234');
    await s.tokens.write(res.token);
    return res.user;
  }

  /// Runs `pnpm staff <args>` in laundry_admin and returns the new status.
  Future<String> staff(List<String> args) async {
    final result = await Process.run('pnpm', [
      '-s',
      'staff',
      ...args,
    ], workingDirectory: adminDir);
    final line = (result.stdout as String).trim().split('\n').last;
    final json = jsonDecode(line) as Map<String, dynamic>;
    if (json['ok'] != true) {
      fail('staff ${args.join(' ')} failed: ${json['error']} ${result.stderr}');
    }
    return json['status'] as String;
  }

  /// Plays the payment provider: sends the signed webhook laundry_admin's
  /// mock gateway expects (dev secret unless PAYMENT_WEBHOOK_SECRET is set).
  Future<void> gateway(PaymentInfo payment, String event) async {
    final body = jsonEncode({
      'provider': payment.provider.name,
      'reference': payment.reference,
      'event': event,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    final secret =
        Platform.environment['PAYMENT_WEBHOOK_SECRET'] ??
        'dev-payment-webhook-secret';
    final sig = await Process.run(
      'sh',
      ['-c', r'printf %s "$BODY" | openssl dgst -sha256 -hmac "$SECRET" -r'],
      environment: {'BODY': body, 'SECRET': secret},
    );
    final signature = (sig.stdout as String).split(' ').first.trim();
    final client = HttpClient();
    try {
      final req = await client.postUrl(
        Uri.parse('$baseUrl/api/payments/webhooks/${payment.provider.name}'),
      );
      req.headers
        ..contentType = ContentType.json
        ..set('x-mock-signature', signature);
      req.write(body);
      final res = await req.close();
      await res.drain<void>();
      expect(res.statusCode, 200, reason: 'webhook $event');
    } finally {
      client.close();
    }
  }

  Future<File> photo() async {
    final file = File(
      '${Directory.systemTemp.path}/laundry_live_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    // A minimal JPEG header is enough for the upload path.
    await file.writeAsBytes([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      ...List.filled(64, 0),
      0xFF,
      0xD9,
    ]);
    return file;
  }

  late ({ApiClient api, _MemoryTokens tokens, List<int> unauthorized}) customer;
  late ({ApiClient api, _MemoryTokens tokens, List<int> unauthorized}) driver;
  late CatalogApiDataSource catalog;
  late OrderApiDataSource orders;
  late DriverTaskApiDataSource tasks;
  late String addressId;

  /// Books with the real slot flow: a pickup two days out, then a delivery
  /// slot at least the tier's turnaround after pickup (as the wizard does).
  Future<LaundryOrder> book({
    List<NewOrderLine> lines = const [],
    List<NewOrderItem> items = const [],
    String tierId = 'tier-standard',
    PaymentMethod? paymentMethod,
    CatalogApiDataSource? atCatalog,
    OrderApiDataSource? atOrders,
  }) async {
    final at = atCatalog ?? catalog;
    final placing = atOrders ?? orders;
    final tier = (await at.getTiers()).firstWhere((t) => t.id == tierId);
    final day = DateTime.now().add(const Duration(days: 2));
    final pickup = (await at.getPickupSlots(
      day,
      tierId,
    )).firstWhere((s) => !s.isFull);
    final notBefore = pickup.start.add(Duration(hours: tier.deliveryHours));
    for (var extra = 0; extra < 5; extra++) {
      final deliveryDay = notBefore.toLocal().add(Duration(days: extra));
      final slots = await at.getDeliverySlots(deliveryDay, tierId, notBefore);
      final open = slots.where((s) => !s.isFull);
      if (open.isNotEmpty) {
        expect(
          open.first.start.isBefore(notBefore),
          isFalse,
          reason: 'server honoured notBefore',
        );
        return placing.createOrder(
          NewOrderParams(
            lines: lines,
            items: items,
            tierId: tierId,
            paymentMethod: paymentMethod,
            pickupSlotId: pickup.id,
            deliverySlotId: open.first.id,
            addressId: addressId,
          ),
        );
      }
    }
    fail('no delivery slot found');
  }

  setUpAll(() async {
    if (skip != null) return;
    customer = session();
    driver = session();
    final user = await signIn(customer, customerPhone);
    expect(user.role, UserRole.customer);
    final d = await signIn(driver, driverPhone);
    expect(d.role, UserRole.driver);
    catalog = CatalogApiDataSource(customer.api);
    orders = OrderApiDataSource(customer.api);
    tasks = DriverTaskApiDataSource(driver.api);
    addressId = (await AddressApiDataSource(
      customer.api,
    ).getAddresses()).first.id;
    await tasks.setAvailability(true);
  });

  group('auth', () {
    test(
      'rejects a non-UAE number and a wrong code with the server\'s message',
      () async {
        final auth = AuthApiDataSource(session().api);
        await expectLater(
          auth.requestOtp('+201001234567'),
          throwsA(
            isA<ServerException>().having((e) => e.statusCode, 'status', 400),
          ),
        );
        await auth.requestOtp(customerPhone);
        await expectLater(
          auth.verifyOtp(customerPhone, '0000'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'Invalid code',
            ),
          ),
        );
      },
    );

    test('a bad token is a 401: UnauthorizedException and the session-expired hook', () async {
      final s = session();
      await s.tokens.write('not-a-real-token');
      await expectLater(
        AuthApiDataSource(s.api).getMe(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(s.unauthorized, hasLength(1));
    });

    test(
      'lookup says Log in for a known number, Verify for a new one',
      () async {
        final auth = AuthApiDataSource(session().api);
        expect(await auth.isRegistered(customerPhone), isTrue);
        expect(await auth.isRegistered(driverPhone), isTrue);
        final fresh =
            '+97150${DateTime.now().millisecondsSinceEpoch % 10000000}'
                .padRight(13, '0');
        expect(await auth.isRegistered(fresh), isFalse);
        await expectLater(
          auth.isRegistered('+201001234567'),
          throwsA(
            isA<ServerException>().having((e) => e.statusCode, 'status', 400),
          ),
        );

        // Verifying a new number with a name creates the account with it.
        await auth.requestOtp(fresh);
        final created = await auth.verifyOtp(
          fresh,
          '1234',
          fullName: 'Sara Ahmed',
        );
        expect(created.user.fullName, 'Sara Ahmed');
        expect(await auth.isRegistered(fresh), isTrue);

        // A known number keeps its name whatever is typed.
        await auth.requestOtp(customerPhone);
        final existing = await auth.verifyOtp(
          customerPhone,
          '1234',
          fullName: 'Someone Else',
        );
        expect(existing.user.fullName, isNot('Someone Else'));
      },
    );

    test('me and profile update', () async {
      final auth = AuthApiDataSource(customer.api);
      final me = await auth.getMe();
      expect(me.profileCompleted, isTrue);
      final updated = await auth.updateProfile(me.fullName!);
      expect(updated.fullName, me.fullName);
    });
  }, skip: skip);

  test('addresses: add, update, list, delete', () async {
    final ds = AddressApiDataSource(customer.api);
    final added = await ds.addAddress(
      const NewAddress(
        kind: AddressKind.work,
        city: 'Abu Dhabi',
        area: 'Al Reem',
        building: 'Sky Tower',
        floor: '30',
        apartment: '3004',
        latitude: 24.49,
        longitude: 54.40,
      ),
    );
    expect(added.kind, AddressKind.work);
    final updated = await ds.updateAddress(
      added.id,
      const NewAddress(
        kind: AddressKind.other,
        label: 'Gym',
        city: 'Abu Dhabi',
        area: 'Al Reem',
        building: 'Sky Tower',
        apartment: '1',
      ),
    );
    expect(updated.label, 'Gym');
    expect((await ds.getAddresses()).map((a) => a.id), contains(added.id));
    await ds.deleteAddress(added.id);
    expect(
      (await ds.getAddresses()).map((a) => a.id),
      isNot(contains(added.id)),
    );
  }, skip: skip);

  test('catalogue in both languages', () async {
    final en = await catalog.getCategories();
    final ar = await CatalogApiDataSource(session(lang: 'ar').api)
        .getCategories();
    expect(en.firstWhere((c) => c.id == 'cat-clothes').name, 'Clothes');
    expect(ar.firstWhere((c) => c.id == 'cat-clothes').name, 'ملابس');
    expect(await catalog.getSubServices('cat-clothes'), isNotEmpty);
    final products = await catalog.getProducts();
    expect(products.firstWhere((p) => p.id == 'prod-shirt').unitPrice, 10);
    final tiers = await catalog.getTiers();
    expect(tiers.firstWhere((t) => t.isVip).surchargeFor(100), 15);
  }, skip: skip);

  test('quick order: book → assign → pickup → receive → invoice → pay → dispatch → deliver → rate', () async {
    var order = await book(
      lines: const [
        NewOrderLine(categoryId: 'cat-clothes', subServiceId: 'sub-wash-iron'),
      ],
    );
    expect(order.status, OrderStatus.pending);
    expect(order.lines.single.subService.id, 'sub-wash-iron');
    expect(order.invoice, isNull);

    expect(await staff(['assign', order.id, driverId]), 'driverAssigned');
    order = await orders.getOrder(order.id);
    expect(order.driverName, isNotNull);

    // The driver app opens task details through GET /api/orders/{id}.
    final asDriver = await OrderApiDataSource(driver.api).getOrder(order.id);
    expect(asDriver.status, OrderStatus.driverAssigned);
    final otherDriver = session();
    await signIn(otherDriver, '+971500000002');
    await expectLater(
      OrderApiDataSource(otherDriver.api).getOrder(order.id),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 404),
      ),
    );

    final today = await tasks.getTodayTasks();
    expect(
      today.any((t) => t.type == TaskType.pickup && t.order.id == order.id),
      isTrue,
    );
    expect((await tasks.confirmPickup(order.id)).status, OrderStatus.pickedUp);

    expect(await staff(['receive', order.id]), 'atFacility');
    expect(
      await staff([
        'invoice',
        order.id,
        jsonEncode([
          {'productId': 'prod-shirt', 'quantity': 3},
          {
            'nameEn': 'Silk scarf',
            'nameAr': 'وشاح حرير',
            'quantity': 1,
            'unitPrice': 18.5,
          },
        ]),
        jsonEncode([
          {'itemName': 'Shirt', 'kind': 'stain', 'note': 'Ink on the cuff'},
        ]),
      ]),
      'awaitingPayment',
    );

    order = await orders.getOrder(order.id);
    expect(order.status, OrderStatus.awaitingPayment);
    expect(order.invoice!.subtotal, 48.5);
    expect(order.invoice!.conditions.single.note, 'Ink on the cuff');

    await expectLater(
      orders.choosePaymentMethod(
        order.id,
        PaymentMethod.cashOnDelivery,
        conditionsAcknowledged: false,
      ),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 400),
      ),
    );
    order = await orders.choosePaymentMethod(
      order.id,
      PaymentMethod.cashOnDelivery,
      conditionsAcknowledged: true,
    );
    expect(order.status, OrderStatus.processing);
    expect(order.invoice!.codFee, 5);
    expect(order.invoice!.total, 53.5);
    expect(order.invoice!.paid, isFalse);

    expect(await staff(['dispatch', order.id, driverId]), 'outForDelivery');
    expect(
      (await tasks.getTodayTasks()).any(
        (t) => t.type == TaskType.delivery && t.order.id == order.id,
      ),
      isTrue,
    );
    await expectLater(
      tasks.confirmDelivery(order.id, cashCollected: false),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 400),
      ),
    );
    final proof = await photo();
    order = await tasks.confirmDelivery(
      order.id,
      cashCollected: true,
      proofPhotoPath: proof.path,
    );
    expect(order.status, OrderStatus.delivered);
    expect(order.invoice!.paid, isTrue);

    order = await orders.rateOrder(order.id, stars: 5, comment: 'Spotless');
    expect(order.rating!.stars, 5);
    await expectLater(
      orders.rateOrder(order.id, stars: 4),
      throwsA(isA<ServerException>()),
    );

    expect(order.timeline.map((e) => e.status), [
      OrderStatus.pending,
      OrderStatus.driverAssigned,
      OrderStatus.pickedUp,
      OrderStatus.atFacility,
      OrderStatus.awaitingPayment,
      OrderStatus.processing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ]);
    expect(
      (await tasks.getCompletedTasks()).any((t) => t.order.id == order.id),
      isTrue,
    );
    expect((await orders.getOrders()).any((o) => o.id == order.id), isTrue);
  }, skip: skip);

  test('pay later with tabby: declined, retried, paid', () async {
    final payments = PaymentApiDataSource(customer.api);
    final options = await payments.getPaymentOptions();
    final payLater = options.firstWhere(
      (o) => o.method == PaymentMethod.payLater,
    );
    expect(payLater.provider, PaymentProvider.tabby);
    expect(payLater.accepts(10), isFalse);

    var order = await book(
      items: const [NewOrderItem(productId: 'prod-suit', quantity: 2)],
      paymentMethod: PaymentMethod.payLater,
    );
    final first = order.invoice!.payment!;
    expect(first.isPending, isTrue);
    expect(first.provider, PaymentProvider.tabby);
    expect(first.checkoutUrl, contains('/pay/'));

    await gateway(first, 'failed');
    expect((await payments.getPayment(first.id)).status, PaymentStatus.failed);

    order = await payments.retryPayment(order.id);
    final second = order.invoice!.payment!;
    expect(second.id, isNot(first.id));
    expect(second.isPending, isTrue);

    await gateway(second, 'succeeded');
    expect(
      (await payments.getPayment(second.id)).status,
      PaymentStatus.succeeded,
    );
    order = await orders.getOrder(order.id);
    expect(order.invoice!.paid, isTrue);
    expect(order.invoice!.paidAt, isNotNull);
  }, skip: skip);

  test('shop order paid by card, then a failed pickup cancels it', () async {
    var order = await book(
      items: const [NewOrderItem(productId: 'prod-suit', quantity: 2)],
      tierId: 'tier-vip',
      paymentMethod: PaymentMethod.card,
    );
    expect(order.lines, isEmpty);
    expect(order.invoice!.subtotal, 90);
    expect(order.invoice!.vipSurcharge, 13.5);
    // Card opens a hosted checkout; the order is paid once it succeeds.
    expect(order.invoice!.paid, isFalse);
    expect(order.invoice!.payment!.isPending, isTrue);
    await gateway(order.invoice!.payment!, 'succeeded');
    order = await orders.getOrder(order.id);
    expect(order.invoice!.paid, isTrue);
    expect(order.invoice!.payment!.status, PaymentStatus.succeeded);

    await staff(['assign', order.id, driverId]);
    final shot = await photo();
    order = await tasks.reportPickupFailed(
      order.id,
      TaskFailureReason.customerAbsent,
      'Nobody home',
      photoPath: shot.path,
    );
    expect(order.status, OrderStatus.cancelled);
    expect(order.pickupFailedAndCancelled, isTrue);
    expect(order.failure!.reason, TaskFailureReason.customerAbsent);
    expect(order.failure!.photoUrl, startsWith('http'));
    final completed = await tasks.getCompletedTasks();
    expect(
      completed.firstWhere((t) => t.order.id == order.id).type,
      TaskType.pickup,
    );
  }, skip: skip);

  test(
    'shop order skips inspection; a failed delivery goes out again',
    () async {
      var order = await book(
        items: const [NewOrderItem(productId: 'prod-tshirt', quantity: 1)],
        paymentMethod: PaymentMethod.cashOnDelivery,
      );
      expect(order.invoice!.codFee, 5);
      await staff(['assign', order.id, driverId]);
      await tasks.confirmPickup(order.id);
      expect(await staff(['receive', order.id]), 'processing');
      await staff(['dispatch', order.id, driverId]);
      order = await tasks.reportDeliveryFailed(
        order.id,
        TaskFailureReason.wrongAddress,
        null,
      );
      expect(order.status, OrderStatus.deliveryFailed);
      expect(await staff(['retry', order.id, driverId]), 'outForDelivery');
      order = await tasks.confirmDelivery(order.id, cashCollected: true);
      expect(order.status, OrderStatus.delivered);
      expect(
        order.timeline.map((e) => e.status),
        isNot(contains(OrderStatus.atFacility)),
      );
    },
    skip: skip,
  );

  test(
    'notifications: the lifecycle reached the inbox; read-all clears it',
    () async {
      final ds = NotificationApiDataSource(customer.api);
      final inbox = await ds.getNotifications();
      expect(
        inbox.map((n) => n.kind),
        containsAll([
          NotificationKind.invoiceReady,
          NotificationKind.delivered,
        ]),
      );
      await ds.markAllRead();
      expect((await ds.getNotifications()).every((n) => n.read), isTrue);
      final driverInbox = await NotificationApiDataSource(driver.api)
          .getNotifications();
      expect(
        driverInbox.map((n) => n.kind),
        containsAll([NotificationKind.newPickup, NotificationKind.newDelivery]),
      );
    },
    skip: skip,
  );

  test(
    'several laundries: the customer orders from the one they chose',
    () async {
      final laundries = await LaundryApiDataSource(customer.api).getLaundries();
      if (laundries.length < 2) {
        markTestSkipped('Needs a second laundry (add one in the portal).');
        return;
      }
      final other = laundries.last;
      final there = session(laundryId: other.id);
      await there.tokens.write((await customer.tokens.read())!);
      final otherCatalog = CatalogApiDataSource(there.api);
      final otherOrders = OrderApiDataSource(there.api);

      // Its own catalogue: same kind of things, different ids.
      final mainIds = {for (final p in await catalog.getProducts()) p.id};
      final products = await otherCatalog.getProducts();
      expect(products, isNotEmpty);
      expect(products.any((p) => mainIds.contains(p.id)), isFalse);

      final tier = (await otherCatalog.getTiers()).firstWhere((t) => !t.isVip);
      final order = await book(
        items: [NewOrderItem(productId: products.first.id, quantity: 1)],
        tierId: tier.id,
        paymentMethod: PaymentMethod.card,
        atCatalog: otherCatalog,
        atOrders: otherOrders,
      );
      expect(order.laundryId, other.id);
      expect(order.laundryName, other.name);

      // The customer's history spans every laundry.
      final mine = await orders.getOrders();
      expect(mine.any((o) => o.id == order.id), isTrue);
    },
    skip: skip,
  );

  test('push: this phone\'s token is registered and removed', () async {
    const token = 'live-test-token-0123456789abcdef';
    await customer.api.post(
      ApiEndpoints.devices,
      data: {'token': token, 'platform': 'android'},
    );
    await customer.api.delete(ApiEndpoints.devices, data: {'token': token});
  }, skip: skip);

  test('support: FAQs, assistant, hand-off to a person', () async {
    final ds = SupportApiDataSource(customer.api);
    final order = (await orders.getOrders()).first;
    expect(await ds.getInvoiceFaqs(), hasLength(4));
    expect(
      (await ds.askAssistant(order.id, 'why is the price so high?')).understood,
      isTrue,
    );
    expect(
      (await ds.askAssistant(order.id, 'blue elephant')).understood,
      isFalse,
    );
    final req = await ds.requestAgent(order.id, const [
      SupportMessage(author: SupportAuthor.customer, text: 'blue elephant'),
      SupportMessage(
        author: SupportAuthor.assistant,
        text: "I couldn't quite work out what you're asking.",
      ),
    ]);
    expect(req.reference, startsWith('S-'));
  }, skip: skip);
}

class _MemoryTokens implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
