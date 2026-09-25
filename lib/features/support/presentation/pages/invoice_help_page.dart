import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../domain/entities/faq_entry.dart';
import '../cubit/invoice_help_cubit.dart';

/// "Question about this invoice?" — contact is not direct. The customer
/// reads the common answers first, then may ask the assistant, and only the
/// assistant offers a person.
class InvoiceHelpPage extends StatelessWidget {
  const InvoiceHelpPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => sl<InvoiceHelpCubit>(),
      child: DetailPage(
        title: l10n.invoiceHelpTitle,
        bottomBar: ActionBar(
          note: l10n.askAssistantNote,
          children: [
            ActionButton(
              label: l10n.askAssistant,
              tone: ActionTone.secondary,
              icon: const Icon(CupertinoIcons.chat_bubble_2),
              onPressed: () => context.push(Routes.orderAssistant(orderId)),
            ),
          ],
        ),
        child: BlocBuilder<InvoiceHelpCubit, InvoiceHelpState>(
          builder: (context, state) {
            if (state.faqs.isEmpty) {
              return state.loading
                  ? const LoadingView()
                  : ErrorView(
                      message:
                          state.failure?.localized(l10n) ?? l10n.genericError,
                      retryLabel: l10n.retry,
                      onRetry: () => context.read<InvoiceHelpCubit>().load(),
                    );
            }
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                LabelGroup(
                  heading: l10n.commonQuestions,
                  children: [for (final faq in state.faqs) _FaqRow(faq: faq)],
                ),
                const SizedBox(height: DesignSpace.huge),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FaqRow extends StatefulWidget {
  const _FaqRow({required this.faq});

  final FaqEntry faq;

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _open,
          child: LabelRow(
            title: widget.faq.question,
            trailing: Icon(
              _open ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
              color: colors.inkTertiary,
              size: 18,
            ),
            onTap: () => setState(() => _open = !_open),
          ),
        ),
        AnimatedSize(
          duration: DesignMotion.base,
          curve: DesignMotion.settle,
          alignment: AlignmentDirectional.topStart,
          child: _open
              ? Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    DesignSpace.gutter,
                    0,
                    DesignSpace.gutter,
                    DesignSpace.lg,
                  ),
                  child: Text(
                    widget.faq.answer,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.inkSecondary),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
