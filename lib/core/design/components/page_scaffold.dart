import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'stitch.dart';

/// A top-level section: large title collapsing to inline on scroll, the way
/// iOS does it. Used only for the roots of the tab bar.
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
    this.onRefresh,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.tape,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            backgroundColor: colors.tape,
            border: Border(bottom: BorderSide(color: colors.rule, width: 0)),
            automaticallyImplyLeading: false,
            trailing: trailing,
            transitionBetweenRoutes: false,
          ),
          if (onRefresh case final refresh?)
            CupertinoSliverRefreshControl(onRefresh: refresh),
          ...slivers,
          const SliverToBoxAdapter(child: SizedBox(height: DesignSpace.huge)),
        ],
      ),
    );
  }
}

/// A screen pushed onto the stack: inline title, system back, edge-swipe
/// intact. Deep detail screens never take a large title.
class DetailPage extends StatelessWidget {
  const DetailPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.bottomBar,
    this.onBack,
    this.background,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final VoidCallback? onBack;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: background ?? colors.tape,
      appBar: AppBar(
        backgroundColor: background ?? colors.tape,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: onBack ?? () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle case final sub?)
              Text(sub, style: DesignTypography.fibreLine(colors.inkTertiary)),
          ],
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignRule.hair),
          child: StitchRule(color: colors.rule),
        ),
      ),
      body: child,
      bottomNavigationBar: bottomBar,
    );
  }
}

/// A step in a flow. The dots are the only place a sequence is drawn, because
/// the sequence itself is information the customer needs.
class FlowPage extends StatelessWidget {
  const FlowPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.step,
    this.totalSteps = 4,
    this.bottomBar,
    this.onBack,
    this.stepSemantics,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final int? step;
  final int totalSteps;
  final Widget? bottomBar;
  final VoidCallback? onBack;
  final String? stepSemantics;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.tape,
      appBar: AppBar(
        backgroundColor: colors.tape,
        leading: Navigator.canPop(context) || onBack != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: onBack ?? () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(step == null ? DesignRule.hair : 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle case final sub?)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignSpace.sm),
                  child: Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: DesignTypography.fibreLine(colors.inkTertiary),
                  ),
                ),
              if (step case final current?) ...[
                _StepBars(
                  step: current,
                  total: totalSteps,
                  semanticsLabel: stepSemantics,
                ),
                const SizedBox(height: DesignSpace.md),
              ],
              StitchRule(color: colors.rule),
            ],
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Progress as bars beneath, the same modifier the glyphs use.
class _StepBars extends StatelessWidget {
  const _StepBars({
    required this.step,
    required this.total,
    this.semanticsLabel,
  });

  final int step;
  final int total;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticsLabel ?? 'Step $step of $total',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
        child: Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              if (i > 1) const SizedBox(width: DesignSpace.xs),
              Expanded(
                child: AnimatedContainer(
                  duration: DesignMotion.base,
                  curve: DesignMotion.settle,
                  height: DesignRule.heavy,
                  color: i <= step ? colors.ink : colors.rule,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
