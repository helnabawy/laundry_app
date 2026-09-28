import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/core/design/design.dart';
import 'package:laundry_app/core/locale/locale_cubit.dart';
import 'package:laundry_app/core/router/routes.dart';
import 'package:laundry_app/core/theme/theme_cubit.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/auth/presentation/cubit/session_cubit.dart';
import 'package:laundry_app/features/auth/presentation/widgets/account_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

class _MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

void main() {
  late _MockSessionCubit session;
  late LocaleCubit locale;
  late ThemeCubit theme;

  AppUser user(UserRole role) => AppUser(
    id: 'u1',
    phone: '+971501234567',
    role: role,
    profileCompleted: true,
    fullName: 'Khalid Al Mansouri',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language_code': 'en'});
    final prefs = await SharedPreferences.getInstance();
    locale = LocaleCubit(prefs);
    theme = ThemeCubit(prefs);
    session = _MockSessionCubit();
    when(() => session.logout()).thenAnswer((_) async {});
  });

  Future<void> pumpAccount(
    WidgetTester tester, {
    UserRole role = UserRole.customer,
    Locale language = const Locale('en'),
  }) {
    when(() => session.state).thenReturn(SessionAuthenticated(user(role)));
    return tester.pumpRouter(
      GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const AccountPage()),
          stubRoute(Routes.addresses),
        ],
      ),
      locale: language,
      wrap: (child) => MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider.value(value: locale),
          BlocProvider.value(value: theme),
        ],
        child: child,
      ),
    );
  }

  Finder inHeader(Finder finder) => find.descendant(
    of: find.byType(CupertinoSliverNavigationBar),
    matching: finder,
  );

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(BottomSheet), matching: finder);

  group('log out', () {
    testWidgets('sits in the header, not at the foot of the page', (
      tester,
    ) async {
      await pumpAccount(tester);

      expect(inHeader(find.text('Log out')), findsOneWidget);
      expect(find.widgetWithText(ActionButton, 'Log out'), findsNothing);
    });

    testWidgets('asks first, naming the number the code will go to', (
      tester,
    ) async {
      await pumpAccount(tester);

      await tester.tap(inHeader(find.text('Log out')));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Log out?')), findsOneWidget);
      expect(inSheet(find.textContaining('4567')), findsOneWidget);
      verifyNever(() => session.logout());
    });

    testWidgets('cancel keeps the session', (tester) async {
      await pumpAccount(tester);

      await tester.tap(inHeader(find.text('Log out')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      verifyNever(() => session.logout());
    });

    testWidgets('confirming logs out', (tester) async {
      await pumpAccount(tester);

      await tester.tap(inHeader(find.text('Log out')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Log out')));
      await tester.pumpAndSettle();

      verify(() => session.logout()).called(1);
    });

    testWidgets('is in the header for drivers too', (tester) async {
      await pumpAccount(tester, role: UserRole.driver);

      expect(inHeader(find.text('Log out')), findsOneWidget);
    });

    testWidgets('is in the header in Arabic, on the reading-end side', (
      tester,
    ) async {
      await pumpAccount(tester, language: const Locale('ar'));

      final logout = inHeader(find.text('تسجيل الخروج'));
      expect(logout, findsOneWidget);
      // Trailing in RTL is the left edge.
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getCenter(logout).dx, lessThan(screenWidth / 2));
    });

    testWidgets('keeps the number on one line', (tester) async {
      await pumpAccount(tester);

      await tester.tap(inHeader(find.text('Log out')));
      await tester.pumpAndSettle();

      expect(
        inSheet(find.textContaining('+971\u00A050\u00A0123\u00A04567')),
        findsOneWidget,
      );
    });
  });

  group('saved addresses', () {
    testWidgets('customers can open them', (tester) async {
      await pumpAccount(tester);

      await tester.tap(find.text('Saved addresses'));
      await tester.pumpAndSettle();

      expect(find.textContaining('route:${Routes.addresses}'), findsOneWidget);
    });

    testWidgets('drivers have none', (tester) async {
      await pumpAccount(tester, role: UserRole.driver);

      expect(find.text('Saved addresses'), findsNothing);
    });
  });

  group('appearance', () {
    testWidgets('follows the system by default', (tester) async {
      await pumpAccount(tester);

      expect(theme.state, ThemeMode.system);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget);
    });

    testWidgets('picking dark applies and remembers it', (tester) async {
      await pumpAccount(tester);

      await tester.scrollUntilVisible(find.text('DARK'), 100);
      await tester.tap(find.text('DARK'));
      await tester.pumpAndSettle();

      expect(theme.state, ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeCubit(prefs).state, ThemeMode.dark);
    });
  });
}
