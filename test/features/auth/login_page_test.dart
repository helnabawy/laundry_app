import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/core/di/injection.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/core/router/routes.dart';
import 'package:laundry_app/features/auth/domain/entities/phone_number.dart';
import 'package:laundry_app/features/auth/domain/entities/saved_account.dart';
import 'package:laundry_app/features/auth/domain/entities/sign_in_request.dart';
import 'package:laundry_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:laundry_app/features/auth/domain/usecases/check_phone.dart';
import 'package:laundry_app/features/auth/domain/usecases/get_saved_account.dart';
import 'package:laundry_app/features/auth/domain/usecases/request_otp.dart';
import 'package:laundry_app/features/auth/domain/usecases/start_sign_in.dart';
import 'package:laundry_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:laundry_app/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _invalidPhone = 'Enter a valid UAE mobile number (5X XXX XXXX)';

void main() {
  final khalid = SavedAccount(
    phone: PhoneNumber.tryParse('501234567')!,
    fullName: 'Khalid Al Mansouri',
  );
  late _MockAuthRepository repository;

  setUpAll(() => registerFallbackValue(khalid.phone));

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.requestOtp(any()))
        .thenAnswer((_) async => const Ok(null));
    // Only +971 50 123 4567 has an account.
    when(() => repository.isRegistered(any())).thenAnswer(
      (inv) async => Ok(
        (inv.positionalArguments.first as PhoneNumber).e164 == '+971501234567',
      ),
    );
    sl.registerFactory(
      () => LoginCubit(
        StartSignIn(RequestOtp(repository)),
        GetSavedAccount(repository),
        CheckPhone(repository),
      ),
    );
  });

  tearDown(sl.reset);

  Future<void> pumpLogin(WidgetTester tester, {SavedAccount? saved}) {
    when(() => repository.savedAccount()).thenReturn(saved);
    return tester.pumpRouter(
      GoRouter(
        initialLocation: Routes.login,
        routes: [
          GoRoute(
            path: Routes.login,
            builder: (_, _) => const LoginPage(),
            routes: [
              GoRoute(
                path: Routes.otpSegment,
                builder: (_, state) {
                  final request = state.extra! as SignInRequest;
                  return Text(
                    'otp ${request.phone.e164} name:${request.fullName}',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Finder phoneField() => find.byType(TextField).at(0);

  /// The button sits below the fold of the 800×600 test window once the
  /// hint and name field show; scroll to it like a user would.
  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.byType(TextField).at(1);

  group('on a device with no saved account', () {
    testWidgets('starts with just the number', (tester) async {
      await pumpLogin(tester);

      expect(find.text('MOBILE NUMBER'), findsOneWidget);
      expect(find.text('FULL NAME'), findsNothing);
      expect(find.text('Send verification code'), findsOneWidget);
      expect(find.text('WELCOME BACK'), findsNothing);
      expect(find.textContaining('Continue as'), findsNothing);
    });

    testWidgets('a registered number says Log in and asks for no name', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '501234567');
      await tester.pumpAndSettle();

      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('FULL NAME'), findsNothing);
      expect(
        find.text(
          "This number has an account. We'll text you a code to log in.",
        ),
        findsOneWidget,
      );

      await press(tester, 'Log in');

      expect(find.text('otp +971501234567 name:null'), findsOneWidget);
    });

    testWidgets('a new number asks for the full name and says Verify', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '0509876543');
      await tester.pumpAndSettle();

      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Log in'), findsNothing);
    });

    testWidgets('won\'t verify a new number without a name', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '509876543');
      await tester.pumpAndSettle();
      await press(tester, 'Verify');

      expect(find.text('Required'), findsOneWidget);
      verifyNever(() => repository.requestOtp(any()));
    });

    testWidgets('verifies a new number with the typed name', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '0509876543');
      await tester.pumpAndSettle();
      await tester.enterText(nameField(), 'Sara Ahmed');
      await press(tester, 'Verify');

      expect(find.text('otp +971509876543 name:Sara Ahmed'), findsOneWidget);
    });

    testWidgets('switching from a new to a registered number drops the name', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '509876543');
      await tester.pumpAndSettle();
      expect(find.text('FULL NAME'), findsOneWidget);

      await tester.enterText(phoneField(), '501234567');
      await tester.pumpAndSettle();
      expect(find.text('FULL NAME'), findsNothing);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('reports a bad number under the number field', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '12');
      await press(tester, 'Send verification code');

      expect(find.text(_invalidPhone), findsOneWidget);
      verifyNever(() => repository.requestOtp(any()));
      verifyNever(() => repository.isRegistered(any()));
    });
  });

  group('on a device with a saved account', () {
    testWidgets('opens on the account, not the form', (tester) async {
      await pumpLogin(tester, saved: khalid);
      expect(find.text('Log in'), findsOneWidget);

      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Khalid Al Mansouri'), findsOneWidget);
      expect(find.textContaining('+971 50 123 4567'), findsOneWidget);
      expect(find.text('FULL NAME'), findsNothing);
    });

    testWidgets('one tap on the account sends its code', (tester) async {
      await pumpLogin(tester, saved: khalid);

      await tester.tap(find.text('Khalid Al Mansouri'));
      await tester.pumpAndSettle();

      expect(find.text('otp +971501234567 name:null'), findsOneWidget);
      verify(() => repository.requestOtp(khalid.phone)).called(1);
    });

    testWidgets('can switch to another number and back', (tester) async {
      await pumpLogin(tester, saved: khalid);

      await tester.tap(find.text('Use another number'));
      await tester.pumpAndSettle();
      expect(find.text('MOBILE NUMBER'), findsOneWidget);

      await tester.tap(find.text('Continue as Khalid Al Mansouri'));
      await tester.pumpAndSettle();
      expect(find.text('WELCOME BACK'), findsOneWidget);
    });
  });
}
