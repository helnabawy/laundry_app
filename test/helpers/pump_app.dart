import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/core/design/design.dart';
import 'package:laundry_app/core/l10n/l10n.dart';
import 'package:laundry_app/features/addresses/presentation/widgets/address_form_fields.dart';

extension PumpApp on WidgetTester {
  /// Pumps [router] inside the app's theme and localizations. [wrap] puts
  /// app-level providers above the navigator, where `LaundryApp` puts them.
  Future<void> pumpRouter(
    GoRouter router, {
    Locale locale = const Locale('en'),
    Widget Function(Widget child)? wrap,
  }) async {
    DesignTypography.script = locale.languageCode;
    await pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
        builder: (context, child) => wrap?.call(child!) ?? child!,
      ),
    );
    await pumpAndSettle();
  }

  /// Pumps a single [page] as the only route.
  Future<void> pumpPage(
    Widget page, {
    Locale locale = const Locale('en'),
    Widget Function(Widget child)? wrap,
  }) => pumpRouter(
    GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => page)],
    ),
    locale: locale,
    wrap: wrap,
  );
}

/// The text field written on a stamped [LabelField] rule.
Finder labelledField(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label.toUpperCase()),
    matching: find.byType(LabelField),
  ),
  matching: find.byType(TextFormField),
);

/// A route that only prints where the app navigated, and with what, so a
/// test can assert a push without building the real destination.
GoRoute stubRoute(String path) => GoRoute(
  path: path,
  builder: (_, state) =>
      Scaffold(body: Text('route:${state.uri} extra:${state.extra}')),
);
