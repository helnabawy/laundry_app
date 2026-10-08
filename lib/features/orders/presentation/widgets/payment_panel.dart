import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/payment_info.dart';
import '../cubit/payment_status_cubit.dart';
import '../utils/payment_launcher.dart';

/// Where an online payment stands, and the one next step: finish paying,
/// check again after coming back, or try again after a decline.
///
/// Give it a new [key] per payment id, so a retried payment starts fresh.
class PaymentPanel extends StatelessWidget {
  const PaymentPanel({
    super.key,
    required this.payment,
    required this.onSettled,
    this.onRetry,
    this.autoLaunch = false,
  });

  /// Null when the order is waiting on an online payment but no checkout
  /// could be opened yet — shown like a failed attempt.
  final PaymentInfo? payment;

  /// The payment reached a final state (paid, declined, expired…).
  final ValueChanged<PaymentInfo> onSettled;

  /// Opens a fresh checkout and returns it; null hides "Retry payment".
  final Future<PaymentInfo?> Function()? onRetry;

  /// Open the checkout as soon as the panel appears (right after the
  /// customer chose to pay).
  final bool autoLaunch;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentStatusCubit>()..track(payment),
      child: _PaymentPanelView(
        onSettled: onSettled,
        onRetry: onRetry,
        autoLaunch: autoLaunch,
      ),
    );
  }
}

class _PaymentPanelView extends StatefulWidget {
  const _PaymentPanelView({
    required this.onSettled,
    required this.onRetry,
    required this.autoLaunch,
  });

  final ValueChanged<PaymentInfo> onSettled;
  final Future<PaymentInfo?> Function()? onRetry;
  final bool autoLaunch;

  @override
  State<_PaymentPanelView> createState() => _PaymentPanelViewState();
}

class _PaymentPanelViewState extends State<_PaymentPanelView>
    with WidgetsBindingObserver {
  final _launcher = sl<PaymentLauncher>();
  var _retrying = false;

  /// Payments opened by "Retry payment": the panel that replaces this one
  /// (keyed by the new id) opens them on sight.
  static final _launchOnSight = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final id = context.read<PaymentStatusCubit>().state.payment?.id;
    if (widget.autoLaunch || _launchOnSight.remove(id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final payment = context.read<PaymentStatusCubit>().state.payment;
        if (mounted && payment != null && payment.isPending) _launch(payment);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the provider's page: ask whether it went through.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PaymentStatusCubit>().check();
    }
  }

  Future<void> _launch(PaymentInfo payment) async {
    final cubit = context.read<PaymentStatusCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final opened = await _launcher.open(context, payment);
    if (!mounted) return;
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.paymentOpenFailed)));
      return;
    }
    // The mock sheet has already settled it; a browser tab settles while
    // the app is away and is checked on return (or "I've finished paying").
    if (!_launcher.leavesApp) await cubit.check();
  }

  Future<void> _retry() async {
    final retry = widget.onRetry;
    if (retry == null || _retrying) return;
    setState(() => _retrying = true);
    // Marked before the parent rebuilds with the new payment's panel.
    final next = await retry();
    if (next != null && next.isPending) _launchOnSight.add(next.id);
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<PaymentStatusCubit, PaymentStatusState>(
      listenWhen: (prev, curr) =>
          (prev.payment?.isPending ?? false) &&
          curr.payment != null &&
          !curr.payment!.isPending,
      listener: (context, state) => widget.onSettled(state.payment!),
      builder: (context, state) {
        final payment = state.payment;
        final children = <Widget>[];

        if (payment != null && payment.status.isCaptured) {
          children.add(
            NoticeBlock(
              tone: NoticeTone.done,
              glyph: const Icon(CupertinoIcons.checkmark_seal),
              title: l10n.paymentSuccess,
            ),
          );
        } else if (payment != null && payment.isPending) {
          children
            ..add(
              NoticeBlock(
                glyph: const Icon(CupertinoIcons.lock),
                title: l10n.paymentPending,
                message: _launcher.leavesApp
                    ? l10n.completePaymentInBrowser
                    : l10n.paymentPendingBody,
              ),
            )
            ..add(const SizedBox(height: DesignSpace.md))
            ..add(
              ActionButton(
                label: l10n.completePayment,
                onPressed: state.checking ? null : () => _launch(payment),
              ),
            );
          if (_launcher.leavesApp) {
            children
              ..add(const SizedBox(height: DesignSpace.sm))
              ..add(
                ActionButton(
                  label: l10n.iFinishedPaying,
                  tone: ActionTone.secondary,
                  loading: state.checking,
                  onPressed: context.read<PaymentStatusCubit>().check,
                ),
              );
          }
        } else {
          children.add(
            NoticeBlock(
              tone: NoticeTone.caution,
              glyph: const Icon(CupertinoIcons.exclamationmark_triangle),
              title: l10n.paymentFailed,
              message: l10n.paymentFailedBody,
            ),
          );
          if (widget.onRetry != null) {
            children
              ..add(const SizedBox(height: DesignSpace.md))
              ..add(
                ActionButton(
                  label: l10n.retryPayment,
                  loading: _retrying,
                  onPressed: _retry,
                ),
              );
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.xl,
            DesignSpace.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
      },
    );
  }
}
