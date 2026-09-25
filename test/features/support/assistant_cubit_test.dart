import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/error/failures.dart';
import 'package:laundry_app/core/result/result.dart';
import 'package:laundry_app/features/support/domain/entities/assistant_reply.dart';
import 'package:laundry_app/features/support/domain/entities/support_message.dart';
import 'package:laundry_app/features/support/domain/entities/support_request.dart';
import 'package:laundry_app/features/support/domain/repositories/support_repository.dart';
import 'package:laundry_app/features/support/domain/usecases/support_usecases.dart';
import 'package:laundry_app/features/support/presentation/cubit/assistant_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;

  AssistantCubit build() => AssistantCubit(
    'ord-1',
    AskAssistant(repository),
    RequestAgent(repository),
  );

  void reply(AssistantReply answer) => when(
    () => repository.askAssistant(
      orderId: any(named: 'orderId'),
      question: any(named: 'question'),
    ),
  ).thenAnswer((_) async => Ok(answer));

  const answered = AssistantReply(text: 'By card or cash', understood: true);
  const puzzled = AssistantReply(text: 'Not sure', understood: false);
  const request = SupportRequest(id: 'sup-1', reference: 'S-1');

  setUp(() => repository = _MockSupportRepository());

  blocTest<AssistantCubit, AssistantState>(
    'an understood answer asks for feedback, not for a person',
    setUp: () => reply(answered),
    build: build,
    act: (cubit) => cubit.ask('how do I pay?'),
    skip: 1,
    expect: () => [
      isA<AssistantState>()
          .having((s) => s.stage, 'stage', AssistantStage.feedback)
          .having((s) => s.messages.length, 'messages', 2),
    ],
  );

  blocTest<AssistantCubit, AssistantState>(
    'a person is only on offer after the answer did not help',
    setUp: () => reply(answered),
    build: build,
    act: (cubit) async {
      await cubit.requestAgent(); // too early: ignored
      await cubit.ask('how do I pay?');
      cubit.markNotHelpful();
    },
    verify: (cubit) {
      expect(cubit.state.stage, AssistantStage.offerAgent);
      verifyNever(
        () => repository.requestAgent(
          orderId: any(named: 'orderId'),
          transcript: any(named: 'transcript'),
        ),
      );
    },
  );

  blocTest<AssistantCubit, AssistantState>(
    'an unmatched question offers a person straight away',
    setUp: () => reply(puzzled),
    build: build,
    act: (cubit) => cubit.ask('something odd'),
    verify: (cubit) => expect(cubit.state.stage, AssistantStage.offerAgent),
  );

  blocTest<AssistantCubit, AssistantState>(
    'handing off sends the transcript and closes the conversation',
    setUp: () {
      reply(puzzled);
      when(
        () => repository.requestAgent(
          orderId: any(named: 'orderId'),
          transcript: any(named: 'transcript'),
        ),
      ).thenAnswer((_) async => const Ok(request));
    },
    build: build,
    act: (cubit) async {
      await cubit.ask('something odd');
      await cubit.requestAgent();
    },
    verify: (cubit) {
      expect(cubit.state.stage, AssistantStage.handedOff);
      expect(cubit.state.request, request);
      expect(cubit.state.canAsk, isFalse);
      verify(
        () => repository.requestAgent(
          orderId: 'ord-1',
          transcript: const [
            SupportMessage(
              author: SupportAuthor.customer,
              text: 'something odd',
            ),
            SupportMessage(author: SupportAuthor.assistant, text: 'Not sure'),
          ],
        ),
      ).called(1);
    },
  );

  blocTest<AssistantCubit, AssistantState>(
    'a failed hand-off keeps the offer open',
    setUp: () {
      reply(puzzled);
      when(
        () => repository.requestAgent(
          orderId: any(named: 'orderId'),
          transcript: any(named: 'transcript'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: build,
    act: (cubit) async {
      await cubit.ask('something odd');
      await cubit.requestAgent();
    },
    verify: (cubit) {
      expect(cubit.state.stage, AssistantStage.offerAgent);
      expect(cubit.state.failure, const NetworkFailure());
      expect(cubit.state.requestingAgent, isFalse);
    },
  );
}
