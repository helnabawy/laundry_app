import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/orders/domain/entities/product.dart';
import 'package:laundry_app/features/orders/domain/entities/service_category.dart';
import 'package:laundry_app/features/orders/domain/repositories/catalog_repository.dart';
import 'package:laundry_app/features/orders/domain/usecases/catalog_usecases.dart';
import 'package:laundry_app/features/shop/presentation/cubit/catalog_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

const _clothes = ServiceCategory(id: 'c-clothes', name: 'Clothes', description: '');
const _carpets = ServiceCategory(id: 'c-carpets', name: 'Carpets', description: '');

const _tshirt = Product(
  id: 'p-tshirt',
  categoryId: 'c-clothes',
  name: 'T-shirt',
  description: '',
  unitPrice: 2,
);
const _rug = Product(
  id: 'p-rug',
  categoryId: 'c-carpets',
  name: 'Rug',
  description: '',
  unitPrice: 40,
);

void main() {
  late _MockCatalogRepository repo;

  CatalogCubit build() => CatalogCubit(GetProducts(repo), GetServiceCategories(repo));

  setUp(() {
    repo = _MockCatalogRepository();
    when(repo.getProducts)
        .thenAnswer((_) async => const Ok([_tshirt, _rug]));
    when(repo.getCategories)
        .thenAnswer((_) async => const Ok([_clothes, _carpets]));
  });

  // The constructor's own `load()` call emits synchronously as the first
  // line of its body — before `blocTest` can attach a listener — so only
  // the final, resolved state is observable here.
  blocTest<CatalogCubit, CatalogState>(
    'load fetches products and categories together',
    build: build,
    expect: () => [
      isA<CatalogState>()
          .having((s) => s.products, 'products', [_tshirt, _rug])
          .having((s) => s.categories, 'categories', [_clothes, _carpets])
          .having((s) => s.loading, 'loading', isFalse)
          .having((s) => s.failure, 'failure', isNull),
    ],
  );

  blocTest<CatalogCubit, CatalogState>(
    'a failed load reports the failure',
    setUp: () => when(repo.getProducts)
        .thenAnswer((_) async => const Err(NetworkFailure())),
    build: build,
    expect: () => [
      isA<CatalogState>()
          .having((s) => s.loading, 'loading', isFalse)
          .having((s) => s.failure, 'failure', const NetworkFailure()),
    ],
  );

  blocTest<CatalogCubit, CatalogState>(
    'selectCategory filters `visible` without refetching',
    build: build,
    act: (cubit) async {
      await pumpEventQueue();
      cubit.selectCategory('c-carpets');
    },
    verify: (cubit) {
      expect(cubit.state.visible, [_rug]);
      expect(cubit.state.selectedCategoryId, 'c-carpets');
      verify(repo.getProducts).called(1);
    },
  );

  blocTest<CatalogCubit, CatalogState>(
    'a null category shows every product',
    build: build,
    act: (cubit) async {
      await pumpEventQueue();
      cubit.selectCategory('c-carpets');
      cubit.selectCategory(null);
    },
    verify: (cubit) => expect(cubit.state.visible, [_tshirt, _rug]),
  );

  blocTest<CatalogCubit, CatalogState>(
    'retry reloads the catalog',
    build: build,
    act: (cubit) async {
      await pumpEventQueue();
      await cubit.retry();
    },
    verify: (_) => verify(repo.getProducts).called(2),
  );
}
