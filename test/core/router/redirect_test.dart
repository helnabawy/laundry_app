import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/router/app_router.dart';
import 'package:laundry_app/core/router/routes.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/auth/presentation/cubit/session_cubit.dart';

void main() {
  AppUser user(UserRole role, {bool completed = true}) => AppUser(
    id: 'u1',
    phone: '+971501234567',
    role: role,
    profileCompleted: completed,
  );

  String? redirect(
    SessionState session,
    String location, {
    bool language = true,
  }) => resolveRedirect(
    session: session,
    hasChosenLanguage: language,
    location: location,
  );

  test('waits on the splash while the session is restored', () {
    expect(redirect(const SessionUnknown(), Routes.login), Routes.splash);
    expect(redirect(const SessionUnknown(), Routes.splash), isNull);
  });

  test('asks for a language on first launch', () {
    expect(
      redirect(const SessionUnauthenticated(), Routes.login, language: false),
      Routes.language,
    );
  });

  test('keeps signed-out users on login / OTP', () {
    expect(
      redirect(const SessionUnauthenticated(), Routes.customerHome),
      Routes.login,
    );
    expect(redirect(const SessionUnauthenticated(), Routes.otp), isNull);
  });

  test('sends new customers to complete their profile', () {
    final session = SessionAuthenticated(
      user(UserRole.customer, completed: false),
    );
    expect(redirect(session, Routes.customerHome), Routes.completeProfile);
  });

  test('lands each role on its own home after login', () {
    expect(
      redirect(SessionAuthenticated(user(UserRole.customer)), Routes.otp),
      Routes.customerHome,
    );
    expect(
      redirect(SessionAuthenticated(user(UserRole.driver)), Routes.otp),
      Routes.driverHome,
    );
  });

  test("keeps each role out of the other's area", () {
    expect(
      redirect(SessionAuthenticated(user(UserRole.customer)), '/driver/x'),
      Routes.customerHome,
    );
    expect(
      redirect(SessionAuthenticated(user(UserRole.driver)), '/customer'),
      Routes.driverHome,
    );
    expect(
      redirect(SessionAuthenticated(user(UserRole.driver)), '/driver/x'),
      isNull,
    );
    expect(
      redirect(SessionAuthenticated(user(UserRole.driver)), Routes.addresses),
      Routes.driverHome,
    );
    expect(
      redirect(
        SessionAuthenticated(user(UserRole.customer)),
        Routes.addAddress,
      ),
      isNull,
    );
  });
}
