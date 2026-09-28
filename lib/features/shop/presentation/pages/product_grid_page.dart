import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/product_tile.dart';

/// The shop flow's flat product catalog: a category filter strip over a
/// two-column grid, with a pinned bottom bar that opens the cart once it
/// holds anything.
class ProductGridPage extends StatelessWidget {
  const ProductGridPage({super.key, this.startWithCategory});

  /// A category id already chosen on Home: the grid opens filtered to it.
  final String? startWithCategory;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = sl<CatalogCubit>();
            if (startWithCategory case final id?) cubit.selectCategory(id);
            return cubit;
          },
        ),
        BlocProvider.value(value: sl<CartCubit>()),
      ],
      child: const _ProductGridView(),
    );
  }
}

class _ProductGridView extends StatelessWidget {
  const _ProductGridView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        final cubit = context.read<CatalogCubit>();
        final labels = [l10n.categoryAll, for (final c in state.categories) c.name];
        final selectedIndex = state.selectedCategoryId == null
            ? 0
            : state.categories.indexWhere(
                    (c) => c.id == state.selectedCategoryId,
                  ) +
                  1;

        return DetailPage(
          title: l10n.shopTitle,
          bottomBar: const CartSummaryBar(),
          child: Column(
            children: [
              if (state.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: DesignSpace.sm),
                  child: ChipStrip(
                    labels: labels,
                    selectedIndex: selectedIndex,
                    onSelected: (i) => cubit.selectCategory(
                      i == 0 ? null : state.categories[i - 1].id,
                    ),
                  ),
                ),
              Expanded(child: _Body(state: state, cubit: cubit)),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.cubit});

  final CatalogState state;
  final CatalogCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.loading && state.products.isEmpty) return const LoadingView();
    if (state.failure != null && state.products.isEmpty) {
      return ErrorView(
        message: state.failure!.localized(l10n),
        retryLabel: l10n.retry,
        onRetry: cubit.retry,
      );
    }
    final visible = state.visible;
    if (visible.isEmpty) return EmptyView(message: l10n.shopEmptyState);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: DesignSpace.sm),
          sliver: ProductGrid(
            itemCount: visible.length,
            itemBuilder: (context, i) => ProductTile(product: visible[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: DesignSpace.huge)),
      ],
    );
  }
}
