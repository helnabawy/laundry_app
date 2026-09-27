import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/core/di/injection.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/core/router/routes.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/addresses/domain/usecases/get_addresses.dart';
import 'package:laundry_app/features/addresses/presentation/cubit/addresses_cubit.dart';
import 'package:laundry_app/features/addresses/presentation/pages/addresses_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockGetAddresses extends Mock implements GetAddresses {}

const _home = Address(
  id: 'adr-1',
  city: 'Abu Dhabi',
  area: 'Al Khalidiyah',
  building: '12',
  apartment: '704',
);
const _gym = Address(
  id: 'adr-3',
  kind: AddressKind.other,
  label: 'Gym',
  city: 'Abu Dhabi',
  area: 'Al Reem',
  building: '9',
  apartment: '1',
);
const _unnamed = Address(
  id: 'adr-4',
  kind: AddressKind.other,
  city: 'Dubai',
  area: 'Marina',
  building: '2',
  apartment: '5',
);

void main() {
  late _MockGetAddresses getAddresses;

  setUp(() {
    getAddresses = _MockGetAddresses();
    sl.registerFactory(() => AddressesCubit(getAddresses));
  });

  tearDown(sl.reset);

  Future<void> pumpAddresses(WidgetTester tester) => tester.pumpRouter(
    GoRouter(
      initialLocation: Routes.addresses,
      routes: [
        GoRoute(
          path: Routes.addresses,
          builder: (_, _) => const AddressesPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('stub form: new'),
                ),
              ),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) =>
                  Text('stub form: edit ${(state.extra! as Address).id}'),
            ),
          ],
        ),
      ],
    ),
  );

  testWidgets('names each address by its kind, or its own name', (
    tester,
  ) async {
    when(() => getAddresses())
        .thenAnswer((_) async => const Ok([_home, _gym, _unnamed]));
    await pumpAddresses(tester);

    expect(find.text('Saved addresses'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    // "Other" with no name of its own falls back to the kind.
    expect(find.text('Other'), findsOneWidget);
    expect(
      find.text('Al Khalidiyah, Abu Dhabi, Building 12, Apt 704'),
      findsOneWidget,
    );
    expect(find.byIcon(CupertinoIcons.house), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.placemark), findsNWidgets(2));
  });

  testWidgets('tapping an address opens it for editing', (tester) async {
    when(() => getAddresses()).thenAnswer((_) async => const Ok([_home, _gym]));
    await pumpAddresses(tester);

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();

    expect(find.text('stub form: edit adr-3'), findsOneWidget);
  });

  testWidgets('comes back from the form with a fresh list', (tester) async {
    var calls = 0;
    when(() => getAddresses()).thenAnswer(
      (_) async => Ok(++calls == 1 ? const [_home] : const [_home, _gym]),
    );
    await pumpAddresses(tester);
    expect(find.text('Gym'), findsNothing);

    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('stub form: new'));
    await tester.pumpAndSettle();

    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    var calls = 0;
    when(() => getAddresses()).thenAnswer(
      (_) async =>
          ++calls == 1 ? const Err(NetworkFailure()) : const Ok([_home]),
    );
    await pumpAddresses(tester);

    expect(
      find.text('No internet connection. Check your network and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
