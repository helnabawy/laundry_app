import 'package:equatable/equatable.dart';

/// The electronic assistant's answer to one customer message.
class AssistantReply extends Equatable {
  const AssistantReply({required this.text, required this.understood});

  final String text;

  /// False when the assistant could not match the question. The customer is
  /// then offered a person straight away instead of being asked whether the
  /// answer helped.
  final bool understood;

  @override
  List<Object?> get props => [text, understood];
}
