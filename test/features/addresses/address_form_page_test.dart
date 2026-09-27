import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/core/di/injection.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/addresses/domain/usecases/add_address.dart';
import 'package:laundry_app/features/addresses/domain/usecases/delete_address.dart';
import 'package:laundry_app/features/addresses/domain/usecases/update_address.dart';
import 'package:laundry_app/features/addresses/presentation/cubit/address_form_cubit.dart';
import 'package:laundry_app/features/addresses/presentation/pages/address_form_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockAddAddress extends Mock implements AddAddress {}

class _MockUpdateAddress extends Mock implements UpdateAddress {}

class _MockDeleteAddress extends Mock implements DeleteAddress {}

const _work = Address(
  id: 'adr-2',
  kind: AddressKind.work,
  city: 'Abu Dhabi',
  area: 'Al Mina',
  building: '3',
  apartment: '210',
);

void main() {
  late _MockAddAddress add;
  late _MockUpdateAddress update;
  late _MockDeleteAddress delete;

  setUpAll(() {
    registerFallbackValue(
      const NewAddress(city: '', area: '', building: '', apartment: ''),
    );
    registerFallbackValue(
      const UpdateAddressParams(
        id: '',
        address: NewAddress(city: '', area: '', building: '', apartment: ''),
      ),
    );
  });

  setUp(() {
    add = _MockAddAddress();
    update = _MockUpdateAddress();
    delete = _MockDeleteAddress();
    sl.registerFactoryParam<AddressFormCubit, Address?, void>(
      (editing, _) => AddressFormCubit(add, update, delete, editing: editing),
    );
  });

  tearDown(sl.reset);

  /// The form pushed over a list, so it has somewhere to pop back to.
  Future<void> pumpForm(WidgetTester tester, {Address? editing}) =>
      tester.pumpRouter(
        GoRouter(
          initialLocation: '/form',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('list')),
              routes: [
                GoRoute(
                  path: 'form',
                  builder: (_, _) => AddressFormPage(editing: editing),
                ),
              ],
            ),
          ],
        ),
      );

  Future<void> fillRequired(WidgetTester tester) async {
    await tester.enterText(labelledField('City'), 'Abu Dhabi');
    await tester.enterText(labelledField('Area'), 'Al Reem');
    await tester.enterText(labelledField('Building'), '9');
    await tester.enterText(labelledField('Apartment'), '1204');
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('adding', () {
    testWidgets('offers Home / Work / Other, starting on Home', (tester) async {
      await pumpForm(tester);

      expect(find.text('Add address'), findsOneWidget);
      for (final kind in ['HOME', 'WORK', 'OTHER']) {
        expect(find.text(kind), findsOneWidget);
      }
      expect(find.text('ADDRESS NAME (OPTIONAL)'), findsNothing);
      expect(find.text('Delete address'), findsNothing);
    });

    testWidgets('only "Other" asks for a name of its own', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('OTHER'));
      await tester.pumpAndSettle();
      expect(find.text('ADDRESS NAME (OPTIONAL)'), findsOneWidget);

      await tester.tap(find.text('WORK'));
      await tester.pumpAndSettle();
      expect(find.text('ADDRESS NAME (OPTIONAL)'), findsNothing);
    });

    testWidgets('saves the chosen kind and name', (tester) async {
      when(() => add(any())).thenAnswer((_) async => const Ok(_work));
      await pumpForm(tester);

      await tester.tap(find.text('OTHER'));
      await tester.pumpAndSettle();
      await tester.enterText(labelledField('Address name (optional)'), 'Gym');
      await fillRequired(tester);
      await tapSave(tester);

      final sent =
          verify(() => add(captureAny())).captured.single as NewAddress;
      expect(sent.kind, AddressKind.other);
      expect(sent.label, 'Gym');
      expect(sent.area, 'Al Reem');
      expect(find.byType(AddressFormPage), findsNothing);
    });

    testWidgets('drops a typed name when the kind changes back', (
      tester,
    ) async {
      when(() => add(any())).thenAnswer((_) async => const Ok(_work));
      await pumpForm(tester);

      await tester.tap(find.text('OTHER'));
      await tester.pumpAndSettle();
      await tester.enterText(labelledField('Address name (optional)'), 'Gym');
      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();
      await fillRequired(tester);
      await tapSave(tester);

      final sent =
          verify(() => add(captureAny())).captured.single as NewAddress;
      expect(sent.kind, AddressKind.home);
      expect(sent.label, isNull);
    });

    testWidgets('won\'t save without the required fields', (tester) async {
      await pumpForm(tester);

      await tapSave(tester);

      expect(find.text('Required'), findsWidgets);
      verifyNever(() => add(any()));
    });
  });

  group('editing', () {
    testWidgets('opens filled in, on the saved kind', (tester) async {
      await pumpForm(tester, editing: _work);

      expect(find.text('Edit address'), findsOneWidget);
      expect(find.text('Al Mina'), findsOneWidget);
      expect(find.text('210'), findsOneWidget);
      expect(find.text('Delete address'), findsOneWidget);
    });

    testWidgets('saves changes to the same address', (tester) async {
      when(() => update(any())).thenAnswer((_) async => const Ok(_work));
      await pumpForm(tester, editing: _work);

      await tester.enterText(labelledField('Apartment'), '211');
      await tapSave(tester);

      final params =
          verify(() => update(captureAny())).captured.single
              as UpdateAddressParams;
      expect(params.id, 'adr-2');
      expect(params.address.apartment, '211');
      expect(params.address.kind, AddressKind.work);
    });

    testWidgets('delete asks first, and cancel keeps it', (tester) async {
      await pumpForm(tester, editing: _work);

      await tester.ensureVisible(find.text('Delete address'));
      await tester.tap(find.text('Delete address'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this address?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => delete(any()));
      expect(find.byType(AddressFormPage), findsOneWidget);
    });

    testWidgets('confirmed delete removes it and closes the form', (
      tester,
    ) async {
      when(() => delete('adr-2')).thenAnswer((_) async => const Ok(null));
      await pumpForm(tester, editing: _work);

      await tester.ensureVisible(find.text('Delete address'));
      await tester.tap(find.text('Delete address'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Delete address'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => delete('adr-2')).called(1);
      expect(find.byType(AddressFormPage), findsNothing);
    });

    testWidgets('the last address can\'t be deleted', (tester) async {
      when(() => delete('adr-2'))
          .thenAnswer((_) async => const Err(LastAddressFailure()));
      await pumpForm(tester, editing: _work);

      await tester.ensureVisible(find.text('Delete address'));
      await tester.tap(find.text('Delete address'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Delete address'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Keep at least one address for pickups'),
        findsOneWidget,
      );
      expect(find.byType(AddressFormPage), findsOneWidget);
    });
  });
}
