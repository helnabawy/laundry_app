import 'package:equatable/equatable.dart';

enum SupportAuthor { customer, assistant }

/// One line of the assistant conversation. Sent along as the transcript when
/// the customer asks for a person, so they never have to repeat themselves.
class SupportMessage extends Equatable {
  const SupportMessage({required this.author, required this.text});

  final SupportAuthor author;
  final String text;

  @override
  List<Object?> get props => [author, text];
}
