import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/laundries/domain/entities/laundry.dart';
import 'package:laundry_app/features/laundries/domain/repositories/laundry_repository.dart';
import 'package:laundry_app/features/laundries/presentation/cubit/laundry_cubit.dart';

class _FakeRepository implements LaundryRepository {
  _FakeRepository({this.saved, this.remote = const []});

  Laundry? saved;
  List<Laundry> remote;
  Failure? failure;

  @override
  Future<Result<List<Laundry>>> getLaundries() async =>
      failure != null ? Err(failure!) : Ok(remote);

  @override
  Laundry? savedLaundry() => saved;

  @override
  Future<void> saveLaundry(Laundry? laundry) async => saved = laundry;
}

void main() {
  const main = Laundry(id: 'fac-1', name: 'Main');
  const marina = Laundry(id: 'fac-2', name: 'Marina');

  test('starts from the laundry saved on this phone, offline', () {
    final cubit = LaundryCubit(_FakeRepository(saved: marina));
    expect(cubit.state.selected, marina);
  });

  test('the only laundry is picked automatically', () async {
    final repo = _FakeRepository(remote: [main]);
    final cubit = LaundryCubit(repo);
    await cubit.load();
    expect(cubit.state.selected, main);
    expect(cubit.state.hasChoice, isFalse);
    expect(repo.saved, main);
  });

  test('with several laundries, nothing is picked for the customer', () async {
    final cubit = LaundryCubit(_FakeRepository(remote: [main, marina]));
    await cubit.load();
    expect(cubit.state.selected, isNull);
    expect(cubit.state.hasChoice, isTrue);
  });

  test('a laundry that stopped taking orders is dropped', () async {
    final repo = _FakeRepository(
      saved: marina,
      remote: [
        main,
        const Laundry(id: 'fac-3', name: 'X'),
      ],
    );
    final cubit = LaundryCubit(repo);
    await cubit.load();
    expect(cubit.state.selected, isNull);
    expect(repo.saved, isNull);
  });

  test('the saved laundry is refreshed with its latest details', () async {
    const renamed = Laundry(id: 'fac-2', name: 'Marina Bay');
    final repo = _FakeRepository(saved: marina, remote: [main, renamed]);
    final cubit = LaundryCubit(repo);
    await cubit.load();
    expect(cubit.state.selected, renamed);
    expect(repo.saved, renamed);
  });

  test('offline, the saved choice stands', () async {
    final repo = _FakeRepository(saved: marina)
      ..failure = const NetworkFailure();
    final cubit = LaundryCubit(repo);
    await cubit.load();
    expect(cubit.state.selected, marina);
    expect(cubit.state.failure, isA<NetworkFailure>());
  });

  test('reordering switches to the laundry that handled the order', () async {
    final repo = _FakeRepository(saved: main, remote: [main, marina]);
    final cubit = LaundryCubit(repo);
    await cubit.switchTo('fac-2');
    expect(cubit.state.selected, marina);
    await cubit.switchTo('gone');
    expect(cubit.state.selected, marina);
    await cubit.switchTo(null);
    expect(cubit.state.selected, marina);
  });
}
