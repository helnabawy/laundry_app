import '../../domain/entities/faq_entry.dart';

abstract final class FaqEntryModel {
  static FaqEntry fromJson(Map<String, dynamic> json) => FaqEntry(
    id: json['id'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
  );
}
