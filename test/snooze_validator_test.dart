import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/utils/snooze_validator.dart';

void main() {
  group('isValidSnoozeMinutes', () {
    test('rejects below minimum', () {
      expect(isValidSnoozeMinutes(0), isFalse);
      expect(isValidSnoozeMinutes(-5), isFalse);
    });

    test('accepts boundaries', () {
      expect(isValidSnoozeMinutes(1), isTrue);
      expect(isValidSnoozeMinutes(1440), isTrue);
    });

    test('rejects above maximum', () {
      expect(isValidSnoozeMinutes(1441), isFalse);
    });
  });
}
