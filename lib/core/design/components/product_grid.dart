import 'package:flutter/widgets.dart';

import '../tokens/design_metrics.dart';

/// A thin, generic wrapper around [SliverGrid] — this design system's first
/// grid layout, kept simple rather than reaching for a bespoke masonry.
/// Two columns, with the system's own spacing rhythm between tiles.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.66,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: DesignSpace.lg,
          crossAxisSpacing: DesignSpace.lg,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
      ),
    );
  }
}
