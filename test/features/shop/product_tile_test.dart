import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/orders/domain/entities/product.dart';
import 'package:laundry_app/features/shop/domain/entities/cart.dart';
import 'package:laundry_app/features/shop/domain/repositories/cart_repository.dart';
import 'package:laundry_app/features/shop/domain/usecases/cart_usecases.dart';
import 'package:laundry_app/features/shop/presentation/cubit/cart_cubit.dart';
import 'package:laundry_app/features/shop/presentation/widgets/product_tile.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockCartRepository extends Mock implements CartRepository {}

const _tshirt = Product(
  id: 'p-tshirt',
  categoryId: 'cat-clothes',
  name: 'T-shirt',
  description: '',
  unitPrice: 2,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const Cart());
  });

  late _MockCartRepository repo;
  late CartCubit cart;

  setUp(() {
    repo = _MockCartRepository();
    when(repo.load).thenAnswer((_) async => const Ok(Cart()));
    when(() => repo.save(any())).thenAnswer((_) async => const Ok(null));
    when(repo.clear).thenAnswer((_) async => const Ok(null));
    cart = CartCubit(LoadCart(repo), SaveCart(repo), ClearCart(repo));
  });

  Future<void> pumpTile(WidgetTester tester) => tester.pumpPage(
    // The tightest real grid cell this tile ever renders in (two columns,
    // childAspectRatio 0.66, on the narrowest supported phone width) — the
    // regression this guards is a RenderFlex overflow at exactly this size.
    Center(
      child: SizedBox(
        width: 170,
        height: 170 / 0.66,
        child: const ProductTile(product: _tshirt),
      ),
    ),
    wrap: (child) => BlocProvider.value(value: cart, child: child),
  );

  testWidgets('renders inside a grid cell with no overflow', (tester) async {
    await pumpTile(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('T-shirt'), findsOneWidget);
  });

  testWidgets('tapping + adds the product to the cart', (tester) async {
    await pumpTile(tester);

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(cart.state.quantityOf(_tshirt.id), 1);

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();

    expect(cart.state.quantityOf(_tshirt.id), 2);
  });
}
