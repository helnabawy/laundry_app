import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../orders/domain/entities/product.dart';
import '../../../orders/domain/entities/service_category.dart';
import '../../../orders/domain/usecases/catalog_usecases.dart';

const _unset = Object();

class CatalogState extends Equatable {
  const CatalogState({
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.loading = true,
    this.failure,
  });

  final List<Product> products;
  final List<ServiceCategory> categories;
  final String? selectedCategoryId;
  final bool loading;
  final Failure? failure;

  /// The products in the current category filter, or every product when
  /// nothing is selected.
  List<Product> get visible => selectedCategoryId == null
      ? products
      : products
            .where((p) => p.categoryId == selectedCategoryId)
            .toList(growable: false);

  CatalogState copyWith({
    List<Product>? products,
    List<ServiceCategory>? categories,
    Object? selectedCategoryId = _unset,
    bool? loading,
    Object? failure = _unset,
  }) => CatalogState(
    products: products ?? this.products,
    categories: categories ?? this.categories,
    selectedCategoryId: identical(selectedCategoryId, _unset)
        ? this.selectedCategoryId
        : selectedCategoryId as String?,
    loading: loading ?? this.loading,
    failure: identical(failure, _unset) ? this.failure : failure as Failure?,
  );

  @override
  List<Object?> get props => [
    products,
    categories,
    selectedCategoryId,
    loading,
    failure,
  ];
}

/// The flat product grid + category filter chips behind the shop page.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._getProducts, this._getCategories)
    : super(const CatalogState()) {
    load();
  }

  final GetProducts _getProducts;
  final GetServiceCategories _getCategories;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: null));
    final (productsResult, categoriesResult) = await (
      _getProducts(),
      _getCategories(),
    ).wait;

    final failure =
        productsResult.failureOrNull ?? categoriesResult.failureOrNull;
    emit(
      state.copyWith(
        products: productsResult.valueOrNull ?? state.products,
        categories: categoriesResult.valueOrNull ?? state.categories,
        loading: false,
        failure: failure,
      ),
    );
  }

  void selectCategory(String? id) =>
      emit(state.copyWith(selectedCategoryId: id));

  Future<void> retry() => load();
}
