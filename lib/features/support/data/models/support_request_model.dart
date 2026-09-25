import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_request.dart';

abstract final class SupportRequestModel {
  static SupportRequest fromJson(Map<String, dynamic> json) => SupportRequest(
    id: json['id'] as String,
    reference: json['reference'] as String,
  );

  static Map<String, dynamic> messageToJson(SupportMessage message) => {
    'author': message.author.name,
    'text': message.text,
  };
}
