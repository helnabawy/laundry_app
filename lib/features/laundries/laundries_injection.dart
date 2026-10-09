import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/laundry_remote_data_source.dart';
import 'data/repositories/laundry_repository_impl.dart';
import 'domain/repositories/laundry_repository.dart';
import 'presentation/cubit/laundry_cubit.dart';

/// Registers the laundry choice. Registered before the features whose API
/// calls carry it (catalogue, slots, orders).
void registerLaundriesFeature(GetIt sl) {
  sl
    ..registerLazySingleton<LaundryRemoteDataSource>(
      () => AppConfig.useMockApi
          ? LaundryMockDataSource(sl())
          : LaundryApiDataSource(sl()),
    )
    ..registerLazySingleton<LaundryRepository>(
      () => LaundryRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => LaundryCubit(sl(), reporter: sl()));
}
