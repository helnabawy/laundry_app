import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/datasources/support_mock_data_source.dart';
import 'data/datasources/support_remote_data_source.dart';
import 'data/repositories/support_repository_impl.dart';
import 'domain/repositories/support_repository.dart';
import 'domain/usecases/support_usecases.dart';
import 'presentation/cubit/assistant_cubit.dart';
import 'presentation/cubit/invoice_help_cubit.dart';

void registerSupportFeature(GetIt sl) {
  sl
    ..registerLazySingleton<SupportRemoteDataSource>(
      () => AppConfig.useMockApi
          ? SupportMockDataSource(sl())
          : SupportApiDataSource(sl()),
    )
    ..registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(sl()),
    )
    ..registerFactory(() => GetInvoiceFaqs(sl()))
    ..registerFactory(() => AskAssistant(sl()))
    ..registerFactory(() => RequestAgent(sl()))
    ..registerFactory(() => InvoiceHelpCubit(sl()))
    ..registerFactoryParam<AssistantCubit, String, void>(
      (orderId, _) => AssistantCubit(orderId, sl(), sl()),
    );
}
