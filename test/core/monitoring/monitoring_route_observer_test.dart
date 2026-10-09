import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/core/monitoring/monitoring_route_observer.dart';

import '../../helpers/fake_reporter.dart';

void main() {
  testWidgets('reports go_router screens by route pattern, with the trail', (
    tester,
  ) async {
    final reporter = RecordingReporter();
    final router = GoRouter(
      observers: [MonitoringRouteObserver(reporter)],
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) => Text('order ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/orders/42');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(reporter.screens, ['/', '/orders/:id', '/']);
    expect(
      reporter.logs,
      containsAllInOrder(['push /orders/:id', 'pop /orders/:id']),
    );
  });

  testWidgets('dialogs are breadcrumbs, not screens', (tester) async {
    final reporter = RecordingReporter();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [MonitoringRouteObserver(reporter)],
        home: const SizedBox(),
      ),
    );
    reporter.screens.clear();
    showDialog<void>(
      context: key.currentContext!,
      builder: (_) => const Text('dialog'),
    );
    await tester.pumpAndSettle();

    expect(reporter.screens, isEmpty);
    expect(reporter.logs.last, 'push DialogRoute');
  });
}
