import '../../domain/entities/time_slot.dart';

abstract final class TimeSlotModel {
  static TimeSlot fromJson(Map<String, dynamic> json) => TimeSlot(
    id: json['id'] as String,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    isFull: json['isFull'] as bool,
  );
}
