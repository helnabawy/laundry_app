import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/monitoring/app_reporter.dart';
import 'package:laundry_app/core/monitoring/breadcrumbs.dart';
import 'package:laundry_app/core/monitoring/default_app_reporter.dart';
import 'package:laundry_app/core/monitoring/sinks.dart';

class _Crash implements CrashReporter {
  final keys = <String, Object>{};
  final lines = <String>[];
  String? userId;
  final recorded = <({Object error, Map<String, Object> keysAtTime})>[];
  List<Object> information = [];

  @override
  Future<void> log(String line) async => lines.add(line);

  @override
  Future<void> setKey(String key, Object value) async => keys[key] = value;

  @override
  Future<void> setUserId(String id) async => userId = id;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    recorded.add((error: error, keysAtTime: {...keys}));
    this.information = information.toList();
  }
}

class _Analytics implements AnalyticsTracker {
  final events = <String, Map<String, Object>>{};
  final screens = <String>[];
  final properties = <String, String?>{};
  String? userId;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async =>
      events[name] = params;

  @override
  Future<void> logScreen(String name) async => screens.add(name);

  @override
  Future<void> setUserId(String? id) async => userId = id;

  @override
  Future<void> setUserProperty(String name, String? value) async =>
      properties[name] = value;
}

void main() {
  late _Crash crash;
  late _Analytics analytics;
  late DefaultAppReporter reporter;

  const user = UserContext(
    id: 'u1',
    role: 'customer',
    phone: '+971501234567',
    name: 'Sara Ali',
    profileCompleted: true,
  );

  setUp(() {
    crash = _Crash();
    analytics = _Analytics();
    reporter = DefaultAppReporter(
      crash: crash,
      analytics: analytics,
      breadcrumbs: Breadcrumbs(clock: () => DateTime(2026, 1, 1, 9, 5, 7)),
    );
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('crash reports carry the full user; analytics never get phone or '
      'name', () async {
    reporter.setUser(user);
    await settle();

    expect(crash.userId, 'u1');
    expect(crash.keys, containsPair('user_phone', '+971501234567'));
    expect(crash.keys, containsPair('user_name', 'Sara Ali'));
    expect(crash.keys, containsPair('user_role', 'customer'));
    expect(crash.keys, containsPair('profile_completed', true));

    expect(analytics.userId, 'u1');
    expect(analytics.properties, {'role': 'customer'});
    expect(
      analytics.properties.values,
      isNot(contains(anyOf('+971501234567', 'Sara Ali'))),
    );
  });

  test('signing out clears the user', () async {
    reporter
      ..setUser(user)
      ..setUser(null);
    await settle();

    expect(crash.userId, '');
    expect(crash.keys['user_phone'], '');
    expect(analytics.userId, isNull);
  });

  test('app context goes to crash keys; only safe keys to analytics', () async {
    reporter
      ..setContext('laundry_id', 'fac-1')
      ..setContext('locale', 'ar')
      ..setContext('api_base_url', 'https://api');
    await settle();

    expect(crash.keys, containsPair('laundry_id', 'fac-1'));
    expect(crash.keys, containsPair('api_base_url', 'https://api'));
    expect(analytics.properties, {'laundry_id': 'fac-1', 'locale': 'ar'});
  });

  test('screens track the current and previous route', () async {
    reporter
      ..screen('/home')
      ..screen('/orders/:id');
    await settle();

    expect(analytics.screens, ['/home', '/orders/:id']);
    expect(crash.keys, containsPair('current_route', '/orders/:id'));
    expect(crash.keys, containsPair('previous_route', '/home'));
  });

  test('an error carries the breadcrumb trail and the request, and the '
      'request keys are cleared afterwards', () async {
    reporter
      ..log('screen /checkout')
      ..log('http POST /orders');
    const request = RequestContext(
      method: 'POST',
      url: 'https://api/orders',
      statusCode: 500,
      body: '{"tierId":"t1"}',
    );
    await reporter.recordError(
      Exception('boom'),
      StackTrace.current,
      request: request,
      extra: {'bloc': 'CheckoutCubit'},
    );

    final keysAtError = crash.recorded.single.keysAtTime;
    expect(keysAtError, containsPair('req_method', 'POST'));
    expect(keysAtError, containsPair('res_status', 500));
    expect(keysAtError, containsPair('req_body', '{"tierId":"t1"}'));
    expect(keysAtError['breadcrumbs'], contains('09:05:07 screen /checkout'));
    expect(keysAtError['breadcrumbs'], contains('✗ POST https://api/orders'));
    expect(crash.information.join(), contains('CheckoutCubit'));

    expect(crash.keys['req_method'], '');
    expect(crash.keys['res_status'], '');
  });

  test('events reach analytics with their params', () async {
    reporter.track(AnalyticsEvent.laundrySelected('fac-2'));
    await settle();

    expect(analytics.events, {
      'laundry_selected': {'laundry_id': 'fac-2'},
    });
  });
}
