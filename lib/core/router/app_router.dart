import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/pages/add_address_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/entities/phone_number.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/language_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../locale/locale_cubit.dart';
import 'refresh_listenable.dart';
import 'routes.dart';

GoRouter createRouter({
  required SessionCubit session,
  required LocaleCubit locale,
}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: StreamRefreshListenable([session.stream, locale.stream]),
    redirect: (context, state) => resolveRedirect(
      session: session.state,
      hasChosenLanguage: locale.hasChosenLanguage,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.language, builder: (_, _) => const LanguagePage()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginPage(),
        routes: [
          GoRoute(
            path: Routes.otpSegment,
            redirect: (_, state) =>
                state.extra is PhoneNumber ? null : Routes.login,
            builder: (_, state) => OtpPage(phone: state.extra! as PhoneNumber),
          ),
        ],
      ),
      GoRoute(
        path: Routes.completeProfile,
        builder: (_, _) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: Routes.addAddress,
        builder: (_, _) => const AddAddressPage(),
      ),
      GoRoute(
        path: Routes.customerHome,
        builder: (_, _) => const _SignedInPlaceholder(),
      ),
      GoRoute(
        path: Routes.driverHome,
        builder: (_, _) => const _SignedInPlaceholder(),
      ),
    ],
  );
}

/// Role-based navigation guard, kept pure for testing.
String? resolveRedirect({
  required SessionState session,
  required bool hasChosenLanguage,
  required String location,
}) {
  if (session is SessionUnknown) {
    return location == Routes.splash ? null : Routes.splash;
  }
  if (!hasChosenLanguage) {
    return location == Routes.language ? null : Routes.language;
  }
  switch (session) {
    case SessionUnknown():
      return null;
    case SessionUnauthenticated():
      return location == Routes.login || location == Routes.otp
          ? null
          : Routes.login;
    case SessionAuthenticated(:final user):
      if (user.role == UserRole.customer && !user.profileCompleted) {
        return location == Routes.completeProfile
            ? null
            : Routes.completeProfile;
      }
      final isDriver = user.role == UserRole.driver;
      final home = isDriver ? Routes.driverHome : Routes.customerHome;
      const entryPoints = {
        Routes.splash,
        Routes.language,
        Routes.login,
        Routes.otp,
        Routes.completeProfile,
      };
      if (entryPoints.contains(location)) return home;
      // Keep each role inside its own area.
      final foreignArea = isDriver ? Routes.customerHome : Routes.driverHome;
      if (location.startsWith(foreignArea)) return home;
      return null;
  }
}

// Replaced by the customer / driver shells in the following features.
class _SignedInPlaceholder extends StatelessWidget {
  const _SignedInPlaceholder();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionCubit>().state;
    final name = state is SessionAuthenticated ? state.user.fullName : null;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name ?? ''),
            TextButton(
              onPressed: context.read<SessionCubit>().logout,
              child: const Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
