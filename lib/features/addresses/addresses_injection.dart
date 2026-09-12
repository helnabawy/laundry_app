import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/address_mock_data_source.dart';
import 'data/datasources/address_remote_data_source.dart';
import 'data/repositories/address_repository_impl.dart';
import 'domain/repositories/address_repository.dart';
import 'domain/usecases/add_address.dart';
import 'domain/usecases/get_addresses.dart';
import 'presentation/cubit/add_address_cubit.dart';

void registerAddressesFeature(GetIt sl) {
  sl
    ..registerLazySingleton<AddressRemoteDataSource>(
      () => AppConfig.useMockApi
          ? AddressMockDataSource(sl())
          : AddressApiDataSource(sl()),
    )
    ..registerLazySingleton<AddressRepository>(
      () => AddressRepositoryImpl(sl()),
    )
    ..registerFactory(() => GetAddresses(sl()))
    ..registerFactory(() => AddAddress(sl()))
    ..registerFactory(() => AddAddressCubit(sl()));
}
