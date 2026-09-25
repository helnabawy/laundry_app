import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/addresses/data/models/address_model.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/addresses/domain/repositories/address_repository.dart';
import 'package:laundry_app/features/addresses/domain/usecases/delete_address.dart';
import 'package:mocktail/mocktail.dart';

class _MockAddressRepository extends Mock implements AddressRepository {}

void main() {
  late _MockAddressRepository repository;
  late DeleteAddress deleteAddress;

  Address address(String id, [AddressKind kind = AddressKind.home]) => Address(
    id: id,
    kind: kind,
    city: 'Abu Dhabi',
    area: 'Al Khalidiyah',
    building: '12',
    apartment: '704',
  );

  setUp(() {
    repository = _MockAddressRepository();
    deleteAddress = DeleteAddress(repository);
  });

  test('refuses to delete the only saved address', () async {
    when(() => repository.getAddresses())
        .thenAnswer((_) async => Ok([address('a1')]));

    final result = await deleteAddress('a1');

    expect(result.failureOrNull, const LastAddressFailure());
    verifyNever(() => repository.deleteAddress(any()));
  });

  test('deletes when another address remains', () async {
    when(() => repository.getAddresses()).thenAnswer(
      (_) async => Ok([address('a1'), address('a2', AddressKind.work)]),
    );
    when(() => repository.deleteAddress('a1'))
        .thenAnswer((_) async => const Ok(null));

    final result = await deleteAddress('a1');

    expect(result.isOk, isTrue);
    verify(() => repository.deleteAddress('a1')).called(1);
  });

  test('round-trips the address kind and treats unknown kinds as other', () {
    final json = {
      ...AddressModel.toJson(address('a1', AddressKind.work).toNewAddress()),
      'id': 'a1',
    };
    expect(AddressModel.fromJson(json).kind, AddressKind.work);
    expect(
      AddressModel.fromJson({...json, 'kind': 'holiday'}).kind,
      AddressKind.other,
    );
  });
}
