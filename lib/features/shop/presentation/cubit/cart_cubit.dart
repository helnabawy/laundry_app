import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../orders/domain/entities/laundry_order.dart';
import '../../../orders/domain/entities/product.dart';
import '../../../orders/domain/entities/service_tier.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/cart_usecases.dart';

/// The cart, shared across Home/Shop/Checkout — sibling pushed routes with
/// no common `BlocProvider` ancestor, hence this being a lazy singleton in
/// DI rather than the usual per-visit factory.
///
/// The cart itself is the display-ready state: no separate wrapper is
/// needed since a loading flag is only relevant for the one initial read.
///
/// Persistence isn't loaded automatically — the DI registration calls
/// [init] once, right after construction — so a freshly-built cubit in a
/// test starts predictably empty until the test itself calls [init].
class CartCubit extends Cubit<Cart> {
  CartCubit(this._loadCart, this._saveCart, this._clearCart)
    : super(const Cart());

  final LoadCart _loadCart;
  final SaveCart _saveCart;
  final ClearCart _clearCart;

  var _initialized = false;

  /// Loads the persisted cart once. Safe to call more than once — later
  /// calls are no-ops once the first load has resolved.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final result = await _loadCart();
    if (isClosed) return;
    if (result.valueOrNull case final cart?) emit(cart);
  }

  void add(Product product, {int quantity = 1}) {
    final next = (state.quantityOf(product.id) ?? 0) + quantity;
    _update(state.withQuantity(product, next));
  }

  void increment(String productId) {
    final line =
        state.lines.where((l) => l.product.id == productId).firstOrNull;
    if (line == null) return;
    _update(state.withQuantity(line.product, line.quantity + 1));
  }

  void decrement(String productId) {
    final line =
        state.lines.where((l) => l.product.id == productId).firstOrNull;
    if (line == null) return;
    _update(state.withQuantity(line.product, line.quantity - 1));
  }

  void setQuantity(String productId, int quantity) {
    final line =
        state.lines.where((l) => l.product.id == productId).firstOrNull;
    if (line == null) return;
    _update(state.withQuantity(line.product, quantity));
  }

  void remove(String productId) {
    final line =
        state.lines.where((l) => l.product.id == productId).firstOrNull;
    if (line == null) return;
    _update(state.withQuantity(line.product, 0));
  }

  void setTier(ServiceTier? tier) => _update(state.withTier(tier));

  void clear() {
    emit(const Cart());
    unawaited(_clearCart().then((_) {}));
  }

  /// Reorder support: repopulates the cart from a past shop-flow order's
  /// invoice lines, resolved against the live catalog by id (a discontinued
  /// or repriced product silently drops rather than showing a stale price).
  /// A no-op if [order] has no invoice (a wizard-flow order never reaches
  /// this cubit, but this stays defensive).
  void loadFrom(LaundryOrder order, List<Product> catalogProducts) {
    final items = order.invoice?.items ?? const [];
    var cart = const Cart();
    for (final item in items) {
      final productId = item.productId;
      if (productId == null) continue;
      final product = catalogProducts
          .where((p) => p.id == productId)
          .firstOrNull;
      if (product == null) continue;
      cart = cart.withQuantity(product, item.quantity);
    }
    _update(cart.withTier(order.tier));
  }

  void _update(Cart cart) {
    emit(cart);
    unawaited(_saveCart(cart).then((_) {}));
  }
}
