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
import '../config/app_config.dart';
import '../locale/locale_cubit.dart';
import '../mock/mock_database.dart';
import '../network/api_client.dart';
import '../network/dio_factory.dart';
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

  sl
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
        ),
      ),
    )
    ..registerLazySingleton(RefreshBus.new)
    ..registerLazySingleton(() => AppResumeObserver(sl())..attach())
    ..registerLazySingleton(() => PushService(api: sl(), refreshBus: sl()));

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
    ),
  );

  sl<AppResumeObserver>();
  await sl<PushService>().init();
  _followSessionAndLaundry();

  // The session is restored once, before the first frame using the router.
  await sl<SessionCubit>().restore();
}

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
