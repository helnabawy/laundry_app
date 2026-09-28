import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../../orders/domain/repositories/catalog_repository.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._local, this._catalog);

  final CartLocalDataSource _local;
  final CatalogRepository _catalog;

  /// Re-resolves every stored id against the live catalog, so a
  /// discontinued or repriced product silently drops out of a restored cart
  /// instead of showing stale data.
  @override
  Future<Result<Cart>> load() async {
    final raw = _local.readRaw();
    if (raw == null) return const Ok(Cart());

    final productsResult = await _catalog.getProducts();
    if (productsResult.failureOrNull case final failure?) return Err(failure);
    final tiersResult = await _catalog.getTiers();
    if (tiersResult.failureOrNull case final failure?) return Err(failure);

    final products = productsResult.valueOrNull!;
    final tiers = tiersResult.valueOrNull!;

    final storedItems =
        (raw['items'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final lines = <CartLine>[
      for (final entry in storedItems.entries)
        if (products.where((p) => p.id == entry.key).firstOrNull
            case final product?)
          CartLine(product: product, quantity: (entry.value as num).toInt()),
    ];
    final tierId = raw['tierId'] as String?;
    final tier = tierId == null
        ? null
        : tiers.where((t) => t.id == tierId).firstOrNull;

    return Ok(Cart(lines: lines, tier: tier));
  }

  @override
  Future<Result<void>> save(Cart cart) => guard(
    () => _local.writeRaw({
      'items': {for (final line in cart.lines) line.product.id: line.quantity},
      'tierId': cart.tier?.id,
    }),
  );

  @override
  Future<Result<void>> clear() => guard(_local.clear);
}
