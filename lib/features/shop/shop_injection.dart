import 'package:get_it/get_it.dart';

import '../orders/domain/entities/laundry_order.dart';
import '../orders/domain/repositories/catalog_repository.dart';
import 'data/datasources/cart_local_data_source.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'domain/repositories/cart_repository.dart';
import 'domain/usecases/cart_usecases.dart';
import 'presentation/cubit/cart_cubit.dart';
import 'presentation/cubit/catalog_cubit.dart';
import 'presentation/cubit/checkout_cubit.dart';

/// Registers the shop feature (product grid, cart, checkout) — additive
/// alongside the existing order wizard, not a replacement for it. Depends on
/// `orders` (`Product`, `ServiceTier`, `CatalogRepository`, `NewOrderParams`,
/// `CreateOrder`) and `addresses` (`Address`, `GetAddresses`), so this is
/// called after both.
void registerShopFeature(GetIt sl) {
  sl
    ..registerLazySingleton(() => CartLocalDataSource(sl()))
    ..registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(sl(), sl<CatalogRepository>()),
    )
    ..registerFactory(() => LoadCart(sl()))
    ..registerFactory(() => SaveCart(sl()))
    ..registerFactory(() => ClearCart(sl()))
    ..registerFactory(() => CatalogCubit(sl(), sl(), refreshBus: sl()))
    // Shared across Home/Shop/Checkout — sibling pushed routes with no
    // common `BlocProvider` ancestor, so this is a singleton rather than the
    // usual per-visit factory.
    ..registerLazySingleton(() => CartCubit(sl(), sl(), sl())..init())
    // param1: the past shop-flow order to repeat, or null for a fresh
    // checkout.
    ..registerFactoryParam<CheckoutCubit, LaundryOrder?, void>(
      (reorderFrom, _) => CheckoutCubit(
        cart: sl(),
        getProducts: sl(),
        getTiers: sl(),
        getPickupSlots: sl(),
        getDeliverySlots: sl(),
        getAddresses: sl(),
        createOrder: sl(),
        getPaymentOptions: sl(),
        retryPayment: sl(),
        reorderFrom: reorderFrom,
        reporter: sl(),
      ),
    );
}
