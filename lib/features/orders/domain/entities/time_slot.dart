import 'package:equatable/equatable.dart';

/// A bookable pickup/delivery window (plan §3 `TimeSlot`). Capacity is a
/// fixed number the facility sets manually, not derived from driver
/// availability — [isFull] is that capacity check already applied.
class TimeSlot extends Equatable {
  const TimeSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.isFull,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final bool isFull;

  @override
  List<Object?> get props => [id, start, end, isFull];
}
