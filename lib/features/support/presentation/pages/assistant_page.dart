import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/support_message.dart';
import '../cubit/assistant_cubit.dart';

/// The electronic assistant for an invoice inquiry. A team member is the
/// last rung, offered only once the assistant has answered and not helped.
class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssistantCubit>(param1: orderId),
      child: const _AssistantView(),
    );
  }
}

class _AssistantView extends StatefulWidget {
  const _AssistantView();

  @override
  State<_AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<_AssistantView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    context.read<AssistantCubit>().ask(text);
  }

  void _followLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: DesignMotion.base,
      curve: DesignMotion.settle,
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AssistantCubit, AssistantState>(
      listener: (context, state) {
        if (state.failure case final failure?) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.localized(l10n))));
        }
        _followLatest();
      },
      builder: (context, state) {
        final cubit = context.read<AssistantCubit>();

        return DetailPage(
          title: l10n.assistantTitle,
          bottomBar: state.stage == AssistantStage.handedOff
              ? null
              : _Composer(
                  controller: _input,
                  enabled: state.canAsk,
                  onSend: _send,
                ),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.xl,
              DesignSpace.gutter,
              DesignSpace.huge,
            ),
            children: [
              _Bubble.assistant(l10n.assistantGreeting),
              for (final message in state.messages)
                message.author == SupportAuthor.customer
                    ? _Bubble.customer(message.text)
                    : _Bubble.assistant(message.text),
              if (state.thinking)
                _Bubble.assistant('…', semanticLabel: l10n.assistantTyping)
              else
                ...switch (state.stage) {
                  AssistantStage.asking => const <Widget>[],
                  AssistantStage.feedback => [
                    _Bubble.assistant(l10n.assistantDidThisHelp),
                    Wrap(
                      spacing: DesignSpace.lg,
                      children: [
                        TintAction(
                          label: l10n.yesThanks,
                          onPressed: cubit.markHelpful,
                        ),
                        TintAction(
                          label: l10n.stillNeedHelp,
                          onPressed: cubit.markNotHelpful,
                        ),
                      ],
                    ),
                  ],
                  AssistantStage.resolved => [
                    _Bubble.assistant(l10n.assistantGlad),
                  ],
                  AssistantStage.offerAgent => [
                    _Bubble.assistant(l10n.assistantOfferAgent),
                    const SizedBox(height: DesignSpace.sm),
                    ActionButton(
                      label: l10n.talkToTeam,
                      tone: ActionTone.secondary,
                      icon: const Icon(CupertinoIcons.person),
                      loading: state.requestingAgent,
                      onPressed: cubit.requestAgent,
                    ),
                  ],
                  AssistantStage.handedOff => [
                    const SizedBox(height: DesignSpace.md),
                    NoticeBlock(
                      tone: NoticeTone.done,
                      glyph: const Icon(CupertinoIcons.checkmark_alt),
                      title: l10n.agentRequestedTitle,
                      message: l10n.agentRequestedBody(
                        state.request?.reference ?? '',
                      ),
                    ),
                  ],
                },
            ],
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble.assistant(this.text, {this.semanticLabel})
    : fromCustomer = false;
  const _Bubble.customer(this.text) : fromCustomer = true, semanticLabel = null;

  final String text;
  final bool fromCustomer;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (ground, ink, border) = fromCustomer
        ? (colors.ink, colors.onInk, colors.ink)
        : (colors.tapeRecessed, colors.ink, colors.rule);

    return Align(
      alignment: fromCustomer
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .8,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignSpace.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSpace.lg,
            vertical: DesignSpace.md,
          ),
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(DesignRadius.panel),
            border: Border.all(color: border, width: DesignRule.hair),
          ),
          child: Text(
            text,
            semanticsLabel: semanticLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ink),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return ActionBar(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(hintText: l10n.assistantInputHint),
              ),
            ),
            const SizedBox(width: DesignSpace.sm),
            IconButton(
              tooltip: l10n.send,
              constraints: const BoxConstraints.tightFor(
                width: DesignSpace.touchTarget,
                height: DesignSpace.touchTarget,
              ),
              onPressed: enabled ? onSend : null,
              icon: Icon(
                CupertinoIcons.arrow_up_circle_fill,
                color: enabled ? colors.tint : colors.inkDisabled,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
