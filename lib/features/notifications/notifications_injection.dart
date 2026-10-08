import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/notification_mock_data_source.dart';
import 'data/datasources/notification_remote_data_source.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/usecases/notification_usecases.dart';
import 'presentation/cubit/notifications_cubit.dart';

void registerNotificationsFeature(GetIt sl) {
  sl
    ..registerLazySingleton<NotificationRemoteDataSource>(
      () => AppConfig.useMockApi
          ? NotificationMockDataSource(sl())
          : NotificationApiDataSource(sl()),
    )
    ..registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(sl()),
    )
    ..registerFactory(() => GetNotifications(sl()))
    ..registerFactory(() => MarkAllNotificationsRead(sl()))
    ..registerFactory(() => NotificationsCubit(sl(), sl(), refreshBus: sl()));
}
