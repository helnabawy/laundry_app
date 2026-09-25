import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/address_mock_data_source.dart';
import 'data/datasources/address_remote_data_source.dart';
import 'data/repositories/address_repository_impl.dart';
import 'domain/entities/address.dart';
import 'domain/repositories/address_repository.dart';
import 'domain/usecases/add_address.dart';
import 'domain/usecases/delete_address.dart';
import 'domain/usecases/get_addresses.dart';
import 'domain/usecases/update_address.dart';
import 'presentation/cubit/address_form_cubit.dart';
import 'presentation/cubit/addresses_cubit.dart';

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
    ..registerFactory(() => UpdateAddress(sl()))
    ..registerFactory(() => DeleteAddress(sl()))
    ..registerFactory(() => AddressesCubit(sl()))
    ..registerFactoryParam<AddressFormCubit, Address?, void>(
      (editing, _) => AddressFormCubit(sl(), sl(), sl(), editing: editing),
    );
}
