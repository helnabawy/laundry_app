import 'dart:collection';

/// The last [capacity] things that happened — screens, requests, state
/// changes, logs — oldest first, so an error report shows how the user got
/// there.
class Breadcrumbs {
  Breadcrumbs({this.capacity = 50, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final int capacity;
  final DateTime Function() _clock;
  final _lines = Queue<String>();

  /// Adds [message] stamped with the time; returns the stamped line.
  String add(String message) {
    final now = _clock();
    final line =
        '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)} '
        '$message';
    _lines.addLast(line);
    while (_lines.length > capacity) {
      _lines.removeFirst();
    }
    return line;
  }

  List<String> get lines => List.unmodifiable(_lines);

  /// The most recent lines, newest last, that fit in [maxLength] chars.
  String tail(int maxLength) {
    final out = <String>[];
    var length = 0;
    for (final line in _lines.toList().reversed) {
      if (length + line.length + 1 > maxLength) break;
      out.insert(0, line);
      length += line.length + 1;
    }
    return out.join('\n');
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
