import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/assistant_reply.dart';
import '../../domain/entities/faq_entry.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_request.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_data_source.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._remote);

  final SupportRemoteDataSource _remote;

  @override
  Future<Result<List<FaqEntry>>> getInvoiceFaqs() =>
      guard(_remote.getInvoiceFaqs);

  @override
  Future<Result<AssistantReply>> askAssistant({
    required String orderId,
    required String question,
  }) => guard(() => _remote.askAssistant(orderId, question));

  @override
  Future<Result<SupportRequest>> requestAgent({
    required String orderId,
    required List<SupportMessage> transcript,
  }) => guard(() => _remote.requestAgent(orderId, transcript));
}
