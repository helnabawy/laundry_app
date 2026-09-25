import 'package:go_router/go_router.dart';

import '../../features/addresses/domain/entities/address.dart';
import '../../features/addresses/presentation/pages/address_form_page.dart';
import '../../features/addresses/presentation/pages/addresses_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/entities/phone_number.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/language_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/orders/domain/entities/laundry_order.dart';
import '../../features/orders/presentation/pages/customer_home_shell.dart';
import '../../features/orders/presentation/pages/delivery_detail_page.dart';
import '../../features/orders/presentation/pages/driver_home_shell.dart';
import '../../features/orders/presentation/pages/invoice_page.dart';
import '../../features/orders/presentation/pages/order_tracking_page.dart';
import '../../features/orders/presentation/pages/order_wizard_page.dart';
import '../../features/orders/presentation/pages/pickup_detail_page.dart';
import '../../features/support/presentation/pages/assistant_page.dart';
import '../../features/support/presentation/pages/invoice_help_page.dart';
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
        path: Routes.addresses,
        builder: (_, _) => const AddressesPage(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const AddressFormPage()),
          GoRoute(
            path: ':id/edit',
            redirect: (_, state) =>
                state.extra is Address ? null : Routes.addresses,
            builder: (_, state) =>
                AddressFormPage(editing: state.extra! as Address),
          ),
        ],
      ),
      GoRoute(
        path: Routes.customerHome,
        builder: (_, _) => const CustomerHomeShell(),
      ),
      GoRoute(
        path: Routes.orderNew,
        // `extra` is the past order being repeated, when reordering.
        builder: (_, state) => OrderWizardPage(
          reorderFrom: switch (state.extra) {
            final LaundryOrder order => order,
            _ => null,
          },
        ),
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
            routes: [
              GoRoute(
                path: 'help',
                builder: (_, state) =>
                    InvoiceHelpPage(orderId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'assistant',
                    builder: (_, state) =>
                        AssistantPage(orderId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
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
      // Keep each role inside its own area (order and address screens are
      // customer-only; `/driver/...` is driver-only).
      const customerAreaPrefixes = [
        Routes.customerHome,
        '/orders',
        Routes.addresses,
      ];
      final inCustomerArea = customerAreaPrefixes.any(location.startsWith);
      final inDriverArea = location.startsWith(Routes.driverHome);
      if (isDriver && inCustomerArea) return home;
      if (!isDriver && inDriverArea) return home;
      return null;
  }
}
