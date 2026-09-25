import 'package:equatable/equatable.dart';

enum TaskFailureReason {
  customerAbsent,
  wrongAddress,
  customerRescheduled,
  other;

  static TaskFailureReason fromJson(String value) =>
      TaskFailureReason.values.firstWhere((r) => r.name == value, orElse: () => TaskFailureReason.other);
}

/// What the driver reported when a pickup or delivery couldn't happen.
///
/// Kept on the order so the customer sees why, and so support has the
/// driver's photo when the customer disputes it.
class TaskFailure extends Equatable {
  const TaskFailure({required this.reason, this.note, this.hasPhoto = false});

  final TaskFailureReason reason;
  final String? note;
  final bool hasPhoto;

  @override
  List<Object?> get props => [reason, note, hasPhoto];
}
