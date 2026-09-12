import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/auth/domain/entities/phone_number.dart';
import 'package:laundry_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:laundry_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late VerifyOtp verifyOtp;
  final phone = PhoneNumber.tryParse('501234567')!;

  AppUser user(UserRole role) => AppUser(
    id: 'u1',
    phone: phone.e164,
    role: role,
    profileCompleted: true,
  );

  setUpAll(() => registerFallbackValue(phone));

  setUp(() {
    repository = _MockAuthRepository();
    verifyOtp = VerifyOtp(repository);
  });

  test('rejects malformed codes without calling the API', () async {
    final result = await verifyOtp(VerifyOtpParams(phone: phone, code: '12'));

    expect(result.failureOrNull, const InputFailure(InputError.invalidOtp));
    verifyNever(() => repository.verifyOtp(any(), any()));
  });

  test('normalizes Arabic-Indic digits before verifying', () async {
    when(
      () => repository.verifyOtp(phone, '1234'),
    ).thenAnswer((_) async => Ok(user(UserRole.customer)));

    final result = await verifyOtp(
      VerifyOtpParams(phone: phone, code: '١٢٣٤'),
    );

    expect(result.valueOrNull, user(UserRole.customer));
  });

  test('signs out staff accounts, which must use the web portal', () async {
    when(
      () => repository.verifyOtp(phone, '1234'),
    ).thenAnswer((_) async => Ok(user(UserRole.staff)));
    when(() => repository.logout()).thenAnswer((_) async => const Ok(null));

    final result = await verifyOtp(VerifyOtpParams(phone: phone, code: '1234'));

    expect(result.failureOrNull, isA<UnsupportedRoleFailure>());
    verify(() => repository.logout()).called(1);
  });
}
