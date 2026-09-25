import 'package:equatable/equatable.dart';

/// A canned answer shown before the customer reaches the assistant.
class FaqEntry extends Equatable {
  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;

  @override
  List<Object?> get props => [id, question, answer];
}
