import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/utils/validators.dart';

void main() {
  group('Validators', () {
    group('Email Validation', () {
      test('should validate correct email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
      });

      test('should reject invalid email', () {
        expect(Validators.validateEmail('invalid-email'), isNotNull);
      });

      test('should reject empty email', () {
        expect(Validators.validateEmail(null), isNotNull);
        expect(Validators.validateEmail(''), isNotNull);
      });
    });

    group('Phone Validation', () {
      test('should validate Turkish phone', () {
        expect(Validators.validatePhone('5551234567', isTurkish: true), isNull);
      });

      test('should reject invalid Turkish phone', () {
        expect(Validators.validatePhone('1234567890', isTurkish: true), isNotNull);
      });
    });

    group('Password Validation', () {
      test('should validate strong password', () {
        expect(Validators.validatePassword('Password123!'), isNull);
      });

      test('should reject weak password', () {
        expect(Validators.validatePassword('short'), isNotNull);
      });
    });

    group('Numeric Range Validation', () {
      test('should validate value in range', () {
        expect(Validators.validateNumericRange('50', min: 0, max: 100), isNull);
      });

      test('should reject value out of range', () {
        expect(Validators.validateNumericRange('150', min: 0, max: 100), isNotNull);
      });
    });
  });
}

