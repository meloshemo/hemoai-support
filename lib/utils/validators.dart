/// Professional input validation utilities
/// Provides reusable validators for forms and user input
library;

import 'package:hemoai/services/localization_service.dart';

class Validators {
  /// Email validation regex pattern (simplified, RFC 5322 compliant)
  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  /// Phone number validation regex (international format)
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );

  /// Turkish phone number validation (10-11 digits without country code)
  static final RegExp _turkishPhoneRegex = RegExp(
    r'^(\+90|0)?[5][0-9]{9}$',
  );

  /// URL validation regex
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// Validate email address
  static String? validateEmail(String? value, {String? customError, LocalizationService? loc}) {
    final localization = loc ?? LocalizationService();
    if (value == null || value.trim().isEmpty) {
      return customError ?? localization.getString('email_required');
    }

    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return customError ?? localization.getString('please_enter_valid_email');
    }

    // Additional length check
    if (trimmed.length > 254) {
      return localization.getString('email_too_long');
    }

    return null;
  }

  /// Validate phone number (international format)
  static String? validatePhone(String? value, {String? customError, bool isTurkish = false, LocalizationService? loc}) {
    final localization = loc ?? LocalizationService();
    if (value == null || value.trim().isEmpty) {
      return customError ?? localization.getString('phone_required');
    }

    final trimmed = value.trim();
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

    if (isTurkish) {
      // Turkish phone validation: 10-11 digits, starting with 5
      if (digitsOnly.length < 10 || digitsOnly.length > 11) {
        return customError ?? localization.getString('phone_must_be_10_11_digits');
      }
      if (!_turkishPhoneRegex.hasMatch(trimmed)) {
        return customError ?? localization.getString('turkish_phone_must_start_with_5');
      }
      return null;
    }

    // International format validation
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return customError ?? 'Phone number must be between 10 and 15 digits';
    }
    if (!_phoneRegex.hasMatch(trimmed.startsWith('+') ? trimmed : '+$trimmed')) {
      return customError ?? 'Please enter a valid international phone number';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(
    String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = false,
    String? customError,
  }) {
    if (value == null || value.isEmpty) {
      return customError ?? 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(
    String? value,
    String? password, {
    String? customError,
  }) {
    if (value == null || value.isEmpty) {
      return customError ?? 'Please confirm your password';
    }

    if (value != password) {
      return customError ?? 'Passwords do not match';
    }

    return null;
  }

  /// Validate name (non-empty, reasonable length)
  static String? validateName(String? value, {String? customError, int minLength = 2, int maxLength = 50}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'Name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < minLength) {
      return 'Name must be at least $minLength characters';
    }

    if (trimmed.length > maxLength) {
      return 'Name must be less than $maxLength characters';
    }

    // Allow only letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validate numeric value within range
  static String? validateNumericRange(
    String? value, {
    required double min,
    required double max,
    String? customError,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? '${fieldName ?? "Value"} is required';
    }

    final numericValue = double.tryParse(value.replaceAll(',', '.'));
    if (numericValue == null) {
      return customError ?? 'Please enter a valid number';
    }

    if (numericValue < min || numericValue > max) {
      return '${fieldName ?? "Value"} must be between $min and $max';
    }

    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'URL is required';
    }

    final trimmed = value.trim();
    if (!_urlRegex.hasMatch(trimmed)) {
      return customError ?? 'Please enter a valid URL';
    }

    return null;
  }

  /// Validate OTP code (numeric, specific length)
  static String? validateOtp(String? value, {int length = 6, String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'OTP code is required';
    }

    final trimmed = value.trim();
    if (trimmed.length != length) {
      return 'OTP code must be $length digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'OTP code must contain only numbers';
    }

    return null;
  }

  /// Validate age (0-150)
  static String? validateAge(String? value, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'Age is required';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }

    if (age < 0 || age > 150) {
      return 'Age must be between 0 and 150';
    }

    return null;
  }

  /// Validate height (in cm, 30-300)
  static String? validateHeight(String? value, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'Height is required';
    }

    final height = double.tryParse(value.replaceAll(',', '.'));
    if (height == null) {
      return 'Please enter a valid height';
    }

    if (height < 30 || height > 300) {
      return 'Height must be between 30 and 300 cm';
    }

    return null;
  }

  /// Validate weight (in kg, 1-500)
  static String? validateWeight(String? value, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'Weight is required';
    }

    final weight = double.tryParse(value.replaceAll(',', '.'));
    if (weight == null) {
      return 'Please enter a valid weight';
    }

    if (weight < 1 || weight > 500) {
      return 'Weight must be between 1 and 500 kg';
    }

    return null;
  }

  /// Validate non-empty string
  static String? validateRequired(String? value, {String? customError, String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? '${fieldName ?? "Field"} is required';
    }
    return null;
  }

  /// Validate TC Kimlik No (Turkish ID number, 11 digits)
  static String? validateTCKimlik(String? value, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'TC Kimlik No is required';
    }

    final trimmed = value.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(trimmed)) {
      return customError ?? 'TC Kimlik No must be exactly 11 digits';
    }

    // Basic TC Kimlik validation algorithm
    final digits = trimmed.split('').map(int.parse).toList();
    
    // First digit cannot be 0
    if (digits[0] == 0) {
      return 'TC Kimlik No cannot start with 0';
    }

    // Check sum validation
    final sum1 = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
    final sum2 = digits[1] + digits[3] + digits[5] + digits[7];
    
    if ((sum1 * 7 - sum2) % 10 != digits[9]) {
      return 'Invalid TC Kimlik No';
    }

    if ((sum1 + sum2 + digits[9]) % 10 != digits[10]) {
      return 'Invalid TC Kimlik No';
    }

    return null;
  }

  /// Validate date format (YYYY-MM-DD or DD/MM/YYYY)
  static String? validateDate(String? value, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? 'Date is required';
    }

    final trimmed = value.trim();
    
    // Try YYYY-MM-DD format
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      try {
        DateTime.parse(trimmed);
        return null;
      } catch (e) {
        return 'Invalid date format';
      }
    }

    // Try DD/MM/YYYY format
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed)) {
      final parts = trimmed.split('/');
      try {
        DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        return null;
      } catch (e) {
        return 'Invalid date format';
      }
    }

    return 'Please enter date in YYYY-MM-DD or DD/MM/YYYY format';
  }

  /// Combine multiple validators
  static String? combineValidators(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

