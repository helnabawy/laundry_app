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
    sl.registerFactory(
      () => LoginCubit(
        StartSignIn(RequestOtp(repository)),
        GetSavedAccount(repository),
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
  Finder nameField() => find.byType(TextField).at(1);

  group('on a device with no saved account', () {
    testWidgets('asks for the number and then the name', (tester) async {
      await pumpLogin(tester);

      expect(find.text('MOBILE NUMBER'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('WELCOME BACK'), findsNothing);
      expect(find.textContaining('Continue as'), findsNothing);
    });

    testWidgets('won\'t send a code without a name', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '501234567');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      verifyNever(() => repository.requestOtp(any()));
    });

    testWidgets('sends the code with the typed name', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '0509876543');
      await tester.enterText(nameField(), 'Sara Ahmed');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('otp +971509876543 name:Sara Ahmed'), findsOneWidget);
    });

    testWidgets('reports a bad number under the number field', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(phoneField(), '12');
      await tester.enterText(nameField(), 'Sara');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNothing);
      expect(find.text(_invalidPhone), findsOneWidget);
      verifyNever(() => repository.requestOtp(any()));
    });
  });

  group('on a device with a saved account', () {
    testWidgets('opens on the account, not the form', (tester) async {
      await pumpLogin(tester, saved: khalid);

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
      expect(find.text('FULL NAME'), findsOneWidget);

      await tester.tap(find.text('Continue as Khalid Al Mansouri'));
      await tester.pumpAndSettle();
      expect(find.text('WELCOME BACK'), findsOneWidget);
    });
  });
}
