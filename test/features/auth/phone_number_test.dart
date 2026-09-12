import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/features/auth/domain/entities/phone_number.dart';

void main() {
  group('PhoneNumber.tryParse', () {
    test('accepts a 9-digit UAE mobile number', () {
      expect(PhoneNumber.tryParse('501234567')?.e164, '+971501234567');
    });

    test('strips spaces, a leading 0 and the country code', () {
      for (final input in [
        '0501234567',
        '50 123 4567',
        '+971 50 123 4567',
        '00971501234567',
      ]) {
        expect(
          PhoneNumber.tryParse(input)?.e164,
          '+971501234567',
          reason: input,
        );
      }
    });

    test('accepts Arabic-Indic digits', () {
      expect(PhoneNumber.tryParse('٥٠١٢٣٤٥٦٧')?.e164, '+971501234567');
    });

    test('rejects non-mobile numbers and wrong lengths', () {
      for (final input in ['401234567', '50123456', '5012345678', '']) {
        expect(PhoneNumber.tryParse(input), isNull, reason: input);
      }
    });

    test('formats for display', () {
      expect(PhoneNumber.tryParse('501234567')!.formatted, '+971 50 123 4567');
    });
  });
}
