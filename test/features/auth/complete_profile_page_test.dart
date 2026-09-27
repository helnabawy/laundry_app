import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/di/injection.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/auth/domain/usecases/complete_profile.dart';
import 'package:laundry_app/features/auth/presentation/cubit/complete_profile_cubit.dart';
import 'package:laundry_app/features/auth/presentation/cubit/session_cubit.dart';
import 'package:laundry_app/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class _MockCompleteProfile extends Mock implements CompleteProfile {}

void main() {
  late _MockSessionCubit session;
  late _MockCompleteProfile completeProfile;

  AppUser user({String? name}) => AppUser(
    id: 'u1',
    phone: '+971509876543',
    role: UserRole.customer,
    profileCompleted: false,
    fullName: name,
  );

  setUpAll(
    () => registerFallbackValue(
      const CompleteProfileParams(
        address: NewAddress(city: '', area: '', building: '', apartment: ''),
      ),
    ),
  );

  setUp(() {
    session = _MockSessionCubit();
    completeProfile = _MockCompleteProfile();
    when(() => completeProfile(any()))
        .thenAnswer((_) async => Ok(user(name: 'Sara Ahmed')));
    sl.registerFactory(() => CompleteProfileCubit(completeProfile));
  });

  tearDown(sl.reset);

  Future<void> pumpProfile(WidgetTester tester, {String? name}) {
    when(() => session.state)
        .thenReturn(SessionAuthenticated(user(name: name)));
    return tester.pumpPage(
      const CompleteProfilePage(),
      wrap: (child) =>
          BlocProvider<SessionCubit>.value(value: session, child: child),
    );
  }

  Future<void> fillAddressAndSave(WidgetTester tester) async {
    await tester.enterText(labelledField('City'), 'Abu Dhabi');
    await tester.enterText(labelledField('Area'), 'Al Reem');
    await tester.enterText(labelledField('Building'), '9');
    await tester.enterText(labelledField('Apartment'), '1204');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks only for the address when login already named them', (
    tester,
  ) async {
    await pumpProfile(tester, name: 'Sara Ahmed');

    expect(find.text('FULL NAME'), findsNothing);
    expect(find.text('Where should we pick up your items?'), findsOneWidget);

    await fillAddressAndSave(tester);

    final params =
        verify(() => completeProfile(captureAny())).captured.single
            as CompleteProfileParams;
    expect(params.fullName, isNull);
    expect(params.address.area, 'Al Reem');
    verify(() => session.userUpdated(user(name: 'Sara Ahmed'))).called(1);
  });

  testWidgets('falls back to asking the name when it didn\'t save', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('FULL NAME'), findsOneWidget);

    await tester.enterText(labelledField('Full name'), 'Sara Ahmed');
    await fillAddressAndSave(tester);

    final params =
        verify(() => completeProfile(captureAny())).captured.single
            as CompleteProfileParams;
    expect(params.fullName, 'Sara Ahmed');
  });
}
