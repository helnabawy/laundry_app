import '../../domain/entities/assistant_reply.dart';

abstract final class AssistantReplyModel {
  static AssistantReply fromJson(Map<String, dynamic> json) => AssistantReply(
    text: json['text'] as String,
    understood: json['understood'] as bool,
  );
}
