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
import '../../features/orders/presentation/pages/customer_home_shell.dart';
import '../../features/orders/presentation/pages/delivery_detail_page.dart';
import '../../features/orders/presentation/pages/driver_home_shell.dart';
import '../../features/orders/presentation/pages/invoice_page.dart';
import '../../features/orders/presentation/pages/order_tracking_page.dart';
import '../../features/orders/presentation/pages/order_wizard_page.dart';
import '../../features/orders/presentation/pages/pickup_detail_page.dart';
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
        builder: (_, _) => const CustomerHomeShell(),
      ),
      GoRoute(
        path: Routes.orderNew,
        builder: (_, _) => const OrderWizardPage(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderTrackingPage(orderId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'invoice',
            builder: (_, state) =>
                InvoicePage(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.driverHome,
        builder: (_, _) => const DriverHomeShell(),
      ),
      GoRoute(
        path: '/driver/pickup/:orderId',
        builder: (_, state) =>
            PickupDetailPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/driver/delivery/:orderId',
        builder: (_, state) =>
            DeliveryDetailPage(orderId: state.pathParameters['orderId']!),
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
      // Keep each role inside its own area (order screens are customer-only;
      // `/driver/...` is driver-only).
      const customerAreaPrefixes = [Routes.customerHome, '/orders'];
      final inCustomerArea = customerAreaPrefixes.any(location.startsWith);
      final inDriverArea = location.startsWith(Routes.driverHome);
      if (isDriver && inCustomerArea) return home;
      if (!isDriver && inDriverArea) return home;
      return null;
  }
}
