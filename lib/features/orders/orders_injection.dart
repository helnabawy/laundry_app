import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/catalog_api_data_source.dart';
import 'data/datasources/catalog_mock_data_source.dart';
import 'data/datasources/catalog_remote_data_source.dart';
import 'data/datasources/driver_task_api_data_source.dart';
import 'data/datasources/driver_task_remote_data_source.dart';
import 'data/datasources/order_api_data_source.dart';
import 'data/datasources/order_mock_data_source.dart';
import 'data/datasources/order_remote_data_source.dart';
import 'data/repositories/catalog_repository_impl.dart';
import 'data/repositories/driver_task_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'domain/entities/laundry_order.dart';
import 'domain/repositories/catalog_repository.dart';
import 'domain/repositories/driver_task_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/usecases/catalog_usecases.dart';
import 'domain/usecases/driver_task_usecases.dart';
import 'domain/usecases/order_usecases.dart';
import 'presentation/cubit/driver_tasks_cubit.dart';
import 'presentation/cubit/order_tracking_cubit.dart';
import 'presentation/cubit/order_wizard_cubit.dart';
import 'presentation/cubit/orders_cubit.dart';
import 'presentation/cubit/task_detail_cubit.dart';

void registerOrdersFeature(GetIt sl) {
  if (AppConfig.useMockApi) {
    // OrderMockDataSource backs both the customer and driver contracts so
    // they share one in-memory `orders` table (see its doc comment).
    sl
      ..registerLazySingleton(() => CatalogMockDataSource(sl()))
      ..registerLazySingleton<CatalogRemoteDataSource>(
        () => sl<CatalogMockDataSource>(),
      )
      ..registerLazySingleton(() => OrderMockDataSource(sl(), sl()))
      ..registerLazySingleton<OrderRemoteDataSource>(
        () => sl<OrderMockDataSource>(),
      )
      ..registerLazySingleton<DriverTaskRemoteDataSource>(
        () => sl<OrderMockDataSource>(),
      );
  } else {
    sl
      ..registerLazySingleton<CatalogRemoteDataSource>(
        () => CatalogApiDataSource(sl()),
      )
      ..registerLazySingleton<OrderRemoteDataSource>(
        () => OrderApiDataSource(sl()),
      )
      ..registerLazySingleton<DriverTaskRemoteDataSource>(
        () => DriverTaskApiDataSource(sl()),
      );
  }

  sl
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(sl()),
    )
    ..registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()))
    ..registerLazySingleton<DriverTaskRepository>(
      () => DriverTaskRepositoryImpl(sl()),
    )
    // Catalog
    ..registerFactory(() => GetServiceCategories(sl()))
    ..registerFactory(() => GetSubServices(sl()))
    ..registerFactory(() => GetServiceTiers(sl()))
    ..registerFactory(() => GetPickupSlots(sl()))
    ..registerFactory(() => GetDeliverySlots(sl()))
    // Orders
    ..registerFactory(() => CreateOrder(sl()))
    ..registerFactory(() => GetOrders(sl()))
    ..registerFactory(() => GetOrder(sl()))
    ..registerFactory(() => ChoosePaymentMethod(sl()))
    ..registerFactory(() => RateOrder(sl()))
    // Driver tasks
    ..registerFactory(() => GetTodayTasks(sl()))
    ..registerFactory(() => GetCompletedTasks(sl()))
    ..registerFactory(() => SetAvailability(sl()))
    ..registerFactory(() => ConfirmPickup(sl()))
    ..registerFactory(() => ReportPickupFailed(sl()))
    ..registerFactory(() => ConfirmDelivery(sl()))
    ..registerFactory(() => ReportDeliveryFailed(sl()))
    // Cubits
    ..registerFactory(() => OrdersCubit(sl()))
    // param1: the past order to repeat, or null for a fresh order.
    ..registerFactoryParam<OrderWizardCubit, LaundryOrder?, void>(
      (reorderFrom, _) => OrderWizardCubit(
        getCategories: sl(),
        getSubServices: sl(),
        getTiers: sl(),
        getPickupSlots: sl(),
        getDeliverySlots: sl(),
        getAddresses: sl(),
        createOrder: sl(),
        reorderFrom: reorderFrom,
      ),
    )
    ..registerFactoryParam<OrderTrackingCubit, String, void>(
      (orderId, _) => OrderTrackingCubit(orderId, sl(), sl(), sl()),
    )
    ..registerFactory(() => DriverTasksCubit(sl(), sl(), sl()))
    ..registerFactoryParam<TaskDetailCubit, String, void>(
      (orderId, _) => TaskDetailCubit(orderId, sl(), sl(), sl(), sl(), sl()),
    );
}
