import '../../../../core/result/result.dart';
import '../entities/cart.dart';

/// Persistence for the cart, re-resolved against the live catalog on load so
/// a discontinued or repriced product never lingers as stale data.
abstract interface class CartRepository {
  Future<Result<Cart>> load();
  Future<Result<void>> save(Cart cart);
  Future<Result<void>> clear();
}
