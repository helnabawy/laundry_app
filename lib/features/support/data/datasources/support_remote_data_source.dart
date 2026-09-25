import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/assistant_reply.dart';
import '../../domain/entities/faq_entry.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_request.dart';
import '../models/assistant_reply_model.dart';
import '../models/faq_entry_model.dart';
import '../models/support_request_model.dart';

abstract interface class SupportRemoteDataSource {
  Future<List<FaqEntry>> getInvoiceFaqs();
  Future<AssistantReply> askAssistant(String orderId, String question);
  Future<SupportRequest> requestAgent(
    String orderId,
    List<SupportMessage> transcript,
  );
}

class SupportApiDataSource implements SupportRemoteDataSource {
  const SupportApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<FaqEntry>> getInvoiceFaqs() async {
    final json = await _api.get(ApiEndpoints.supportInvoiceFaqs) as List;
    return json
        .cast<Map<String, dynamic>>()
        .map(FaqEntryModel.fromJson)
        .toList();
  }

  @override
  Future<AssistantReply> askAssistant(String orderId, String question) async {
    final json = await _api.post(
      ApiEndpoints.supportAssistant,
      data: {'orderId': orderId, 'topic': 'invoice', 'question': question},
    );
    return AssistantReplyModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SupportRequest> requestAgent(
    String orderId,
    List<SupportMessage> transcript,
  ) async {
    final json = await _api.post(
      ApiEndpoints.supportRequests,
      data: {
        'orderId': orderId,
        'topic': 'invoice',
        'transcript': transcript
            .map(SupportRequestModel.messageToJson)
            .toList(),
      },
    );
    return SupportRequestModel.fromJson(json as Map<String, dynamic>);
  }
}
