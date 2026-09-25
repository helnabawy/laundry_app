import 'package:equatable/equatable.dart';

/// A hand-off to a person — the last step, only after the assistant.
class SupportRequest extends Equatable {
  const SupportRequest({required this.id, required this.reference});

  final String id;

  /// Short code the customer can quote, e.g. `S-1042`.
  final String reference;

  @override
  List<Object?> get props => [id, reference];
}
