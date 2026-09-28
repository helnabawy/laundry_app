import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/storage/token_storage.dart';
import 'package:laundry_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:laundry_app/features/auth/data/datasources/saved_account_local_data_source.dart';
import 'package:laundry_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/auth/domain/entities/phone_number.dart';
import 'package:laundry_app/features/auth/domain/entities/saved_account.dart';
import 'package:laundry_app/features/auth/domain/usecases/check_phone.dart';
import 'package:laundry_app/features/auth/domain/usecases/get_saved_account.dart';
import 'package:laundry_app/features/auth/domain/usecases/request_otp.dart';
import 'package:laundry_app/features/auth/domain/usecases/start_sign_in.dart';
import 'package:laundry_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MemoryTokens implements TokenStorage {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  final phone = PhoneNumber.tryParse('501234567')!;
  late _MockRemote remote;
  late AuthRepositoryImpl repository;

  AppUser user({String? name, UserRole role = UserRole.customer}) => AppUser(
    id: 'u1',
    phone: phone.e164,
    role: role,
    profileCompleted: true,
    fullName: name,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    remote = _MockRemote();
    repository = AuthRepositoryImpl(
      remote,
      _MemoryTokens(),
      SavedAccountLocalDataSource(await SharedPreferences.getInstance()),
    );
  });

  void answerVerify(AppUser user) => when(
    () =>
        remote.verifyOtp(phone.e164, '1234', fullName: any(named: 'fullName')),
  ).thenAnswer((_) async => (token: 't', user: user));

  group('saved account', () {
    test('is remembered after a named sign-in and survives logout', () async {
      answerVerify(user(name: 'Khalid'));

      await repository.verifyOtp(phone, '1234');
      await repository.logout();

      expect(
        repository.savedAccount(),
        SavedAccount(phone: phone, fullName: 'Khalid'),
      );
    });

    test('waits for a name, then picks it up from the profile', () async {
      answerVerify(user());
      when(() => remote.updateProfile('Khalid'))
          .thenAnswer((_) async => user(name: 'Khalid'));

      await repository.verifyOtp(phone, '1234');
      expect(repository.savedAccount(), isNull);

      await repository.updateProfile(fullName: 'Khalid');
      expect(repository.savedAccount()?.fullName, 'Khalid');
    });

    test('is never kept for staff accounts', () async {
      answerVerify(user(name: 'Operator', role: UserRole.staff));

      await repository.verifyOtp(phone, '1234');

      expect(repository.savedAccount(), isNull);
    });
  });

  group('login', () {
    LoginCubit cubit() => LoginCubit(
      StartSignIn(RequestOtp(repository)),
      GetSavedAccount(repository),
      CheckPhone(repository),
    );

    test('opens on the saved account when there is one', () async {
      answerVerify(user(name: 'Khalid'));
      await repository.verifyOtp(phone, '1234');

      final state = cubit().state;

      expect(state.usingSavedAccount, isTrue);
      expect(state.savedAccount?.fullName, 'Khalid');
    });

    test('opens on the number + name form on a fresh device', () {
      expect(cubit().state.usingSavedAccount, isFalse);
    });

    test('the saved account sends a code without asking for a name', () async {
      answerVerify(user(name: 'Khalid'));
      await repository.verifyOtp(phone, '1234');
      when(() => remote.requestOtp(phone.e164)).thenAnswer((_) async {});

      final login = cubit();
      await login.continueWithSavedAccount();

      expect(login.state.codeSentTo?.phone, phone);
      expect(login.state.codeSentTo?.fullName, isNull);
    });

    test('a new number needs a name before any code is sent', () async {
      when(() => remote.isRegistered(phone.e164))
          .thenAnswer((_) async => false);
      final login = cubit();

      // First press: the number turns out to be new, so the name field
      // appears instead of an error.
      await login.submit(phone: '501234567', fullName: '  ');
      expect(login.state.asksForName, isTrue);
      expect(login.state.failure, isNull);

      // Pressing Verify with the name still blank is an error.
      await login.submit(phone: '501234567', fullName: '  ');
      expect(login.state.nameMissing, isTrue);
      verifyNever(() => remote.requestOtp(any()));
    });

    test('a registered number sends the code without asking a name', () async {
      when(() => remote.isRegistered(phone.e164)).thenAnswer((_) async => true);
      when(() => remote.requestOtp(phone.e164)).thenAnswer((_) async {});
      final login = cubit();

      await login.phoneChanged('501234567');
      expect(login.state.isLogin, isTrue);

      await login.submit(phone: '501234567', fullName: '');
      expect(login.state.codeSentTo?.fullName, isNull);
    });

    test(
      'a slow check for an old number never overrides the current one',
      () async {
        when(() => remote.isRegistered('+971501234567')).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return true;
        });
        when(() => remote.isRegistered('+971509876543'))
            .thenAnswer((_) async => false);
        final login = cubit();

        final slow = login.phoneChanged('501234567');
        await login.phoneChanged('509876543');
        await slow;

        expect(login.state.phoneStatus, PhoneStatus.unregistered);
      },
    );

    test('a bad number is reported before a missing name', () async {
      final login = cubit();
      await login.submit(phone: '12', fullName: '');

      expect(login.state.failure, const InputFailure(InputError.invalidPhone));
    });
  });
}
