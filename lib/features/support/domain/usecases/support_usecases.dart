import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_reply.dart';
import '../entities/faq_entry.dart';
import '../entities/support_message.dart';
import '../entities/support_request.dart';
import '../repositories/support_repository.dart';

class GetInvoiceFaqs implements UseCase<List<FaqEntry>, NoParams> {
  const GetInvoiceFaqs(this._repo);
  final SupportRepository _repo;

  @override
  Future<Result<List<FaqEntry>>> call([NoParams params = const NoParams()]) =>
      _repo.getInvoiceFaqs();
}

class AskAssistant
    implements UseCase<AssistantReply, ({String orderId, String question})> {
  const AskAssistant(this._repo);
  final SupportRepository _repo;

  @override
  Future<Result<AssistantReply>> call(
    ({String orderId, String question}) params,
  ) => _repo.askAssistant(orderId: params.orderId, question: params.question);
}

class RequestAgent
    implements
        UseCase<
          SupportRequest,
          ({String orderId, List<SupportMessage> transcript})
        > {
  const RequestAgent(this._repo);
  final SupportRepository _repo;

  @override
  Future<Result<SupportRequest>> call(
    ({String orderId, List<SupportMessage> transcript}) params,
  ) => _repo.requestAgent(
    orderId: params.orderId,
    transcript: params.transcript,
  );
}
