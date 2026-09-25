import '../../../../core/result/result.dart';
import '../entities/assistant_reply.dart';
import '../entities/faq_entry.dart';
import '../entities/support_message.dart';
import '../entities/support_request.dart';

/// Invoice inquiries (step 4.3). Contact is deliberately not direct: FAQs
/// first, then the assistant, and a person only when the customer asks.
abstract interface class SupportRepository {
  Future<Result<List<FaqEntry>>> getInvoiceFaqs();

  Future<Result<AssistantReply>> askAssistant({
    required String orderId,
    required String question,
  });

  Future<Result<SupportRequest>> requestAgent({
    required String orderId,
    required List<SupportMessage> transcript,
  });
}
