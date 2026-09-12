import 'package:equatable/equatable.dart';

import '../../../../core/utils/digits.dart';

/// A UAE mobile number (`5X XXX XXXX`). The MVP is UAE-only (+971).
class PhoneNumber extends Equatable {
  const PhoneNumber._(this.nationalNumber);

  static final _uaeMobile = RegExp(r'^5\d{8}$');

  /// Nine digits starting with 5, e.g. `501234567`.
  final String nationalNumber;

  /// Accepts `501234567`, `0501234567`, `+971 50 123 4567`, `00971...` and
  /// Arabic-Indic digits. Returns null if it isn't a valid UAE mobile.
  static PhoneNumber? tryParse(String input) {
    var digits = normalizeDigits(input).replaceAll(RegExp('[^0-9]'), '');
    if (digits.startsWith('00971')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('971')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return _uaeMobile.hasMatch(digits) ? PhoneNumber._(digits) : null;
  }

  /// `+971501234567` — the format sent to the API.
  String get e164 => '+971$nationalNumber';

  /// `+971 50 123 4567`
  String get formatted =>
      '+971 ${nationalNumber.substring(0, 2)} '
      '${nationalNumber.substring(2, 5)} ${nationalNumber.substring(5)}';

  @override
  List<Object?> get props => [nationalNumber];
}
