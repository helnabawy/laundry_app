import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/addresses/addresses_injection.dart';
import '../../features/auth/auth_injection.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/notifications/notifications_injection.dart';
import '../../features/orders/orders_injection.dart';
import '../../features/support/support_injection.dart';
import '../config/app_config.dart';
import '../locale/locale_cubit.dart';
import '../mock/mock_database.dart';
import '../network/api_client.dart';
import '../network/dio_factory.dart';
import '../router/app_router.dart';
import '../storage/token_storage.dart';

final sl = GetIt.instance;

/// Composition root. Core services first, then each feature registers its own
/// data sources, repositories, use cases and cubits.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<TokenStorage>(SecureTokenStorage.new)
    ..registerLazySingleton(() => LocaleCubit(sl()))
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
        ),
      ),
    );

  registerAddressesFeature(sl);
  registerAuthFeature(sl);
  registerOrdersFeature(sl);
  registerSupportFeature(sl);
  registerNotificationsFeature(sl);

  sl.registerLazySingleton(
    () => createRouter(session: sl<SessionCubit>(), locale: sl<LocaleCubit>()),
  );

  // The session is restored once, before the first frame using the router.
  await sl<SessionCubit>().restore();
}
