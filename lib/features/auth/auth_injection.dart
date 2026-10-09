import 'package:get_it/get_it.dart';

import '../../core/push/push_service.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/auth_mock_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/saved_account_local_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/check_phone.dart';
import 'domain/usecases/complete_profile.dart';
import 'domain/usecases/get_saved_account.dart';
import 'domain/usecases/request_otp.dart';
import 'domain/usecases/session_usecases.dart';
import 'domain/usecases/start_sign_in.dart';
import 'domain/usecases/verify_otp.dart';
import 'presentation/cubit/complete_profile_cubit.dart';
import 'presentation/cubit/login_cubit.dart';
import 'presentation/cubit/session_cubit.dart';

void registerAuthFeature(GetIt sl) {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AppConfig.useMockApi
          ? AuthMockDataSource(sl(), sl())
          : AuthApiDataSource(sl()),
    )
    ..registerLazySingleton(() => SavedAccountLocalDataSource(sl()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl(), sl()),
    )
    ..registerFactory(() => RequestOtp(sl()))
    ..registerFactory(() => StartSignIn(sl()))
    ..registerFactory(() => GetSavedAccount(sl()))
    ..registerFactory(() => VerifyOtp(sl()))
    ..registerFactory(() => RestoreSession(sl()))
    ..registerFactory(() => Logout(sl()))
    ..registerFactory(() => CompleteProfile(sl(), sl()))
    ..registerLazySingleton(
      () => SessionCubit(
        restoreSession: sl(),
        logout: sl(),
        beforeLogout: () => sl<PushService>().unregister(),
        reporter: sl(),
      ),
    )
    ..registerFactory(() => CheckPhone(sl()))
    ..registerFactory(() => LoginCubit(sl(), sl(), sl(), reporter: sl()))
    ..registerFactory(() => CompleteProfileCubit(sl(), reporter: sl()));
}
