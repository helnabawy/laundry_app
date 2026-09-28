import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:laundry_app/app.dart';
import 'package:laundry_app/core/design/design.dart';
import 'package:laundry_app/core/di/injection.dart';
import 'package:laundry_app/core/mock/mock_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/pump_app.dart';

/// End-to-end flows through the real app, against the in-memory mock backend
/// (`USE_MOCK_API` defaults to true). Run on a simulator or device:
///
/// ```bash
/// flutter test integration_test -d <device id>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A fresh install every time: no session, no saved account, a fresh mock
  /// backend, and English already chosen so each flow starts at login.
  Future<void> launchFreshApp(WidgetTester tester) async {
    // Unmount the previous flow's app first. Pumping `LaundryApp` over it
    // would reuse its elements, carrying state such as an open snackbar
    // into this flow.
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('language_code', 'en');
    await const FlutterSecureStorage().deleteAll();
    await configureDependencies();
    await tester.pumpWidget(const LaundryApp());
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(BottomSheet), matching: finder);

  Finder inHeader(Finder finder) => find.descendant(
    of: find.byType(CupertinoSliverNavigationBar),
    matching: finder,
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), MockDatabase.otpCode);
    await tester.pumpAndSettle();
  }

  Future<void> signInWithNewNumber(
    WidgetTester tester, {
    required String phone,
    required String name,
  }) async {
    await tester.enterText(find.byType(TextField).at(0), phone);
    await tester.enterText(find.byType(TextField).at(1), name);
    await tapAndSettle(tester, find.text('Send verification code'));
    await enterCode(tester);
  }

  Future<void> openAccountTab(WidgetTester tester) => tapAndSettle(
    tester,
    find.descendant(
      of: find.byType(TapeTabBar),
      matching: find.text('Account'),
    ),
  );

  Future<void> fillAddress(
    WidgetTester tester, {
    String area = 'Al Reem',
  }) async {
    await tester.enterText(labelledField('City'), 'Abu Dhabi');
    await tester.enterText(labelledField('Area'), area);
    await tester.enterText(labelledField('Building'), '9');
    await tester.enterText(labelledField('Apartment'), '1204');
  }

  /// Pumps until [finder] matches (or, when [gone], stops matching), or fails after [timeout]. A list reloads
  /// behind its old rows without animating, so `pumpAndSettle` alone returns
  /// before the mock backend's reply has landed.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    bool gone = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty != gone) {
      if (DateTime.now().isAfter(end)) {
        fail('Timed out waiting for ${finder.describeMatch(Plurality.one)}');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<void> deleteAddressNamed(WidgetTester tester, String name) async {
    await tapAndSettle(tester, find.text(name));
    await tester.scrollTo(find.text('Delete address'));
    await tapAndSettle(tester, find.text('Delete address'));
    await tapAndSettle(tester, inSheet(find.text('Delete address')));
  }

  testWidgets(
    'a new customer gives their name at login, logs out from the header, '
    'and signs back in with one tap',
    (tester) async {
      await launchFreshApp(tester);

      // First time: number, then name.
      expect(find.text('WELCOME BACK'), findsNothing);
      await signInWithNewNumber(tester, phone: '509876543', name: 'Sara Ahmed');

      // The name came from login, so onboarding only wants the address.
      expect(find.text('Where should we pick up your items?'), findsOneWidget);
      expect(find.text('FULL NAME'), findsNothing);
      await tapAndSettle(tester, find.text('WORK'));
      await fillAddress(tester);
      await tapAndSettle(tester, find.text('Save'));

      await openAccountTab(tester);
      expect(find.text('Sara Ahmed'), findsOneWidget);

      // Log out lives in the header and asks first.
      await tapAndSettle(tester, inHeader(find.text('Log out')));
      expect(inSheet(find.text('Log out?')), findsOneWidget);
      await tapAndSettle(tester, inSheet(find.text('Log out')));

      // The saved account greets them; one tap sends the code.
      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('FULL NAME'), findsNothing);
      await tapAndSettle(tester, find.text('Sara Ahmed'));
      expect(find.text('+971 50 987 6543'), findsOneWidget);
      await enterCode(tester);

      // Profile is complete now, so they land straight on home.
      expect(find.byType(TapeTabBar), findsOneWidget);
      expect(find.text('Where should we pick up your items?'), findsNothing);
    },
  );

  testWidgets(
    'an existing customer keeps their name and manages saved addresses',
    (tester) async {
      await launchFreshApp(tester);

      // A retyped name never overwrites the one the account already has.
      await signInWithNewNumber(
        tester,
        phone: MockDatabase.customerPhone.substring(4),
        name: 'Someone Else',
      );
      await openAccountTab(tester);
      expect(find.text('خالد المنصوري'), findsOneWidget);
      expect(find.text('Someone Else'), findsNothing);

      await tapAndSettle(tester, find.text('Saved addresses'));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);

      // Add an "Other" address with a name of its own.
      await tapAndSettle(tester, find.text('Add address'));
      await tapAndSettle(tester, find.text('OTHER'));
      await tester.enterText(labelledField('Address name (optional)'), 'Gym');
      await fillAddress(tester);
      await tapAndSettle(tester, find.text('Save'));
      await pumpUntil(tester, find.text('Gym'));

      // Edit it.
      await tapAndSettle(tester, find.text('Gym'));
      expect(find.text('Edit address'), findsOneWidget);
      await tester.enterText(labelledField('Area'), 'Saadiyat');
      await tapAndSettle(tester, find.text('Save'));
      await pumpUntil(tester, find.textContaining('Saadiyat'));

      // Delete down to the last one, which stays.
      await deleteAddressNamed(tester, 'Gym');
      await pumpUntil(tester, find.text('Gym'), gone: true);
      await deleteAddressNamed(tester, 'Work');
      await pumpUntil(tester, find.text('Work'), gone: true);
      await deleteAddressNamed(tester, 'Home');
      expect(
        find.text('Keep at least one address for pickups'),
        findsOneWidget,
      );
      expect(find.text('Edit address'), findsOneWidget);
    },
  );

  testWidgets('drivers log out from the header too, and see no addresses', (
    tester,
  ) async {
    await launchFreshApp(tester);

    await signInWithNewNumber(
      tester,
      phone: MockDatabase.driverPhone.substring(4),
      name: 'Driver',
    );
    await openAccountTab(tester);

    expect(find.text('Saved addresses'), findsNothing);
    await tapAndSettle(tester, inHeader(find.text('Log out')));
    await tapAndSettle(tester, inSheet(find.text('Log out')));

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('أحمد علي'), findsOneWidget);
  });
}
