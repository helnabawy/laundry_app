import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/addresses/addresses_injection.dart';
import '../../features/auth/auth_injection.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/laundries/laundries_injection.dart';
import '../../features/laundries/presentation/cubit/laundry_cubit.dart';
import '../../features/notifications/notifications_injection.dart';
import '../../features/orders/orders_injection.dart';
import '../../features/shop/presentation/cubit/cart_cubit.dart';
import '../../features/shop/shop_injection.dart';
import '../../features/support/support_injection.dart';
import '../../l10n/gen/app_localizations.dart';
import '../config/app_config.dart';
import '../error/guard.dart';
import '../firebase/firebase_bootstrap.dart';
import '../locale/locale_cubit.dart';
import '../mock/mock_database.dart';
import '../monitoring/app_reporter.dart';
import '../monitoring/console_sinks.dart';
import '../monitoring/default_app_reporter.dart';
import '../monitoring/firebase/firebase_analytics_tracker.dart';
import '../monitoring/firebase/firebase_crash_reporter.dart';
import '../monitoring/monitoring_bloc_observer.dart';
import '../network/api_client.dart';
import '../network/dio_factory.dart';
import '../push/local_notifications.dart';
import '../push/push_service.dart';
import '../router/app_router.dart';
import '../storage/token_storage.dart';
import '../sync/refresh_bus.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

/// Composition root. Core services first, then each feature registers its own
/// data sources, repositories, use cases and cubits.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await initFirebase();
  final reporter = await _createReporter(firebaseReady: firebaseReady);
  guardReporter = reporter;
  Bloc.observer = MonitoringBlocObserver(reporter);

  sl
    ..registerSingleton<AppReporter>(reporter)
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<TokenStorage>(SecureTokenStorage.new)
    ..registerLazySingleton(() => LocaleCubit(sl()))
    ..registerLazySingleton(() => ThemeCubit(sl()))
    ..registerLazySingleton(
      () => MockDatabase(languageCode: () => sl<LocaleCubit>().languageCode),
    )
    ..registerLazySingleton(
      () => ApiClient(
        createDio(
          baseUrl: AppConfig.apiBaseUrl,
          tokenStorage: sl(),
          languageCode: () => sl<LocaleCubit>().languageCode,
          onUnauthorized: () => sl<SessionCubit>().expire(),
          laundryId: () => sl<LaundryCubit>().state.selected?.id,
          reporter: sl(),
        ),
      ),
    )
    ..registerLazySingleton(RefreshBus.new)
    ..registerLazySingleton(() => AppResumeObserver(sl())..attach())
    ..registerLazySingleton(
      () => PushService(
        api: sl(),
        refreshBus: sl(),
        // iOS shows foreground pushes itself.
        localNotifications: defaultTargetPlatform == TargetPlatform.android
            ? LocalNotifications()
            : null,
        reporter: sl(),
      ),
    );

  registerLaundriesFeature(sl);
  registerAddressesFeature(sl);
  registerAuthFeature(sl);
  registerOrdersFeature(sl);
  registerShopFeature(sl);
  registerSupportFeature(sl);
  registerNotificationsFeature(sl);

  sl.registerLazySingleton(
    () => createRouter(
      session: sl<SessionCubit>(),
      locale: sl<LocaleCubit>(),
      laundry: sl<LaundryCubit>(),
      reporter: sl(),
    ),
  );

  sl<AppResumeObserver>();
  final l10n = lookupAppLocalizations(Locale(sl<LocaleCubit>().languageCode));
  await sl<PushService>().init(
    firebaseReady: firebaseReady,
    channelName: l10n.pushChannelName,
    channelDescription: l10n.pushChannelDescription,
  );
  _followSessionAndLaundry();
  _reportAppState();

  // The session is restored once, before the first frame using the router.
  await sl<SessionCubit>().restore();
}

/// Crash reporting and analytics on Firebase when it started; otherwise the
/// same reporter printing to the console (mock mode, local development).
Future<AppReporter> _createReporter({required bool firebaseReady}) async {
  if (!firebaseReady) {
    return DefaultAppReporter(
      crash: ConsoleCrashReporter(),
      analytics: ConsoleAnalyticsTracker(),
    );
  }
  final crash = FirebaseCrashReporter();
  await crash.init();
  return DefaultAppReporter(
    crash: crash,
    analytics: FirebaseAnalyticsTracker(),
  );
}

/// Keeps the reporter's context — who is signed in, which laundry, the UI
/// language and theme — current, so every report and event carries it.
void _reportAppState() {
  final reporter = sl<AppReporter>()
    ..setContext('use_mock_api', AppConfig.useMockApi)
    ..setContext('api_base_url', AppConfig.apiBaseUrl);
  final session = sl<SessionCubit>();
  final laundry = sl<LaundryCubit>();
  final locale = sl<LocaleCubit>();
  final theme = sl<ThemeCubit>();

  void onSession(SessionState state) {
    switch (state) {
      case SessionAuthenticated(:final user):
        reporter.setUser(_userContext(user));
      case SessionUnauthenticated(:final expired):
        reporter
          ..setUser(null)
          ..setContext('session_expired', expired);
      case SessionUnknown(:final failure):
        reporter.setContext('session_restore_failure', failure?.runtimeType);
    }
  }

  onSession(session.state);
  session.stream.listen(onSession);
  reporter
    ..setContext('laundry_id', laundry.state.selected?.id)
    ..setContext('laundry_name', laundry.state.selected?.name)
    ..setContext('locale', locale.languageCode)
    ..setContext('theme', theme.state.name);
  laundry.stream.listen(
    (s) => reporter
      ..setContext('laundry_id', s.selected?.id)
      ..setContext('laundry_name', s.selected?.name),
  );
  locale.stream.listen(
    (_) => reporter.setContext('locale', locale.languageCode),
  );
  theme.stream.listen((mode) => reporter.setContext('theme', mode.name));
}

UserContext _userContext(AppUser user) => UserContext(
  id: user.id,
  role: user.role.name,
  phone: user.phone,
  name: user.fullName,
  profileCompleted: user.profileCompleted,
);

/// Keeps push registration, the laundry topic and the cart in step with who
/// is signed in and which laundry they order from.
void _followSessionAndLaundry() {
  final session = sl<SessionCubit>();
  final laundry = sl<LaundryCubit>();
  final push = sl<PushService>();

  String? signedInAs;
  session.stream.listen((state) {
    final user = state is SessionAuthenticated ? state.user : null;
    if (user?.id == signedInAs) return;
    signedInAs = user?.id;
    if (user == null) return;
    final isDriver = user.role == UserRole.driver;
    push.register(isDriver: isDriver);
    if (!isDriver) {
      push.followLaundry(laundry.state.selected?.id);
      // Learn whether there's a choice, and drop a laundry that closed.
      laundry.load();
    }
  });

  var laundryId = laundry.state.selected?.id;
  laundry.stream.listen((state) {
    final id = state.selected?.id;
    if (id == laundryId) return;
    // The cart holds the previous laundry's products and prices.
    if (laundryId != null) sl<CartCubit>().clear();
    laundryId = id;
    if (session.state case SessionAuthenticated(:final user)
        when user.role == UserRole.customer) {
      push.followLaundry(id);
    }
  });
}
