import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_request.dart';
import '../../domain/usecases/support_usecases.dart';

/// Where the conversation stands, which decides what the customer is
/// offered under the last message.
enum AssistantStage {
  /// Waiting for a question.
  asking,

  /// The assistant answered; did it help?
  feedback,

  /// The customer said it helped.
  resolved,

  /// The assistant could not help. A person is now on offer, and the
  /// customer can still rephrase instead.
  offerAgent,

  /// Handed to a person; the conversation is closed here.
  handedOff,
}

class AssistantState extends Equatable {
  const AssistantState({
    this.messages = const [],
    this.stage = AssistantStage.asking,
    this.thinking = false,
    this.requestingAgent = false,
    this.request,
    this.failure,
  });

  final List<SupportMessage> messages;
  final AssistantStage stage;

  /// Waiting on the assistant's reply.
  final bool thinking;

  final bool requestingAgent;

  final SupportRequest? request;
  final Failure? failure;

  bool get canAsk =>
      !thinking && !requestingAgent && stage != AssistantStage.handedOff;

  AssistantState copyWith({
    List<SupportMessage>? messages,
    AssistantStage? stage,
    bool? thinking,
    bool? requestingAgent,
    SupportRequest? request,
    Failure? failure,
  }) => AssistantState(
    messages: messages ?? this.messages,
    stage: stage ?? this.stage,
    thinking: thinking ?? this.thinking,
    requestingAgent: requestingAgent ?? this.requestingAgent,
    request: request ?? this.request,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    messages,
    stage,
    thinking,
    requestingAgent,
    request,
    failure,
  ];
}

/// The second rung: the electronic assistant. A person is the last step and
/// only on the customer's say-so, never offered before the assistant has had
/// a go.
class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this._orderId, this._ask, this._requestAgent)
    : super(const AssistantState());

  final String _orderId;
  final AskAssistant _ask;
  final RequestAgent _requestAgent;

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || !state.canAsk) return;

    final messages = [
      ...state.messages,
      SupportMessage(author: SupportAuthor.customer, text: text),
    ];
    emit(state.copyWith(messages: messages, thinking: true));

    final result = await _ask((orderId: _orderId, question: text));
    emit(
      result.fold(
        onErr: (f) => state.copyWith(thinking: false, failure: f),
        onOk: (reply) => state.copyWith(
          messages: [
            ...messages,
            SupportMessage(author: SupportAuthor.assistant, text: reply.text),
          ],
          stage: reply.understood
              ? AssistantStage.feedback
              : AssistantStage.offerAgent,
          thinking: false,
        ),
      ),
    );
  }

  void markHelpful() {
    if (state.stage != AssistantStage.feedback) return;
    emit(state.copyWith(stage: AssistantStage.resolved));
  }

  void markNotHelpful() {
    if (state.stage != AssistantStage.feedback) return;
    emit(state.copyWith(stage: AssistantStage.offerAgent));
  }

  Future<void> requestAgent() async {
    if (state.stage != AssistantStage.offerAgent || !state.canAsk) return;
    emit(state.copyWith(requestingAgent: true));
    final result = await _requestAgent((
      orderId: _orderId,
      transcript: state.messages,
    ));
    emit(
      result.fold(
        onErr: (f) => state.copyWith(requestingAgent: false, failure: f),
        onOk: (request) => state.copyWith(
          stage: AssistantStage.handedOff,
          requestingAgent: false,
          request: request,
        ),
      ),
    );
  }
}
