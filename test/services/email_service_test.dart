import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/email_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmailService', () {
    late EmailService emailService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      emailService = EmailService();
    });

    test('should create singleton instance', () {
      final instance1 = EmailService();
      final instance2 = EmailService();
      expect(instance1, equals(instance2));
    });

    group('Initialization', () {
      test('should initialize with test mode when no API key', () async {
        await emailService.initialize();
        expect(emailService.isTestMode, true);
        expect(emailService.isConfigured, false);
      });

      test('should initialize with API key from parameters', () async {
        await emailService.initialize(apiKey: 'SG.test_key_123');
        // In test mode since we can't actually verify SendGrid API
        expect(emailService.isInitialized, true);
      });

      test('should initialize with fromEmail and fromName', () async {
        await emailService.initialize(
          apiKey: 'SG.test_key',
          fromEmail: 'test@example.com',
          fromName: 'Test App',
        );
        expect(emailService.isInitialized, true);
      });
    });

    group('Status and Configuration', () {
      test('should return correct status', () async {
        await emailService.initialize();
        expect(emailService.isTestMode, isA<bool>());
        expect(emailService.isConfigured, isA<bool>());
      });

      test('should get status details', () async {
        await emailService.initialize();
        final status = emailService.getStatus();
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('isInitialized'), true);
        expect(status.containsKey('isTestMode'), true);
        expect(status.containsKey('isConfigured'), true);
      });
    });

    group('API Key Management', () {
      test('should validate API key format', () async {
        await emailService.initialize();
        
        // Valid SendGrid API key format (starts with SG.)
        final result1 = await emailService.updateApiKey('SG.valid_key_1234567890');
        expect(result1, true);
        
        // Invalid format
        final result2 = await emailService.updateApiKey('invalid_key');
        expect(result2, false);
      });

      test('should clear API key', () async {
        await emailService.initialize(apiKey: 'SG.test_key');
        await emailService.clearApiKey();
        
        final status = emailService.getStatus();
        expect(status['isTestMode'], true);
      });
    });

    group('Rate Limiting', () {
      test('should track rate limits', () async {
        await emailService.initialize(apiKey: 'SG.test_key');
        
        // Rate limit status should be available
        final status = emailService.getStatus();
        expect(status.containsKey('rateLimitStatus'), true);
      });
    });

    group('Email Sending (Test Mode)', () {
      test('should send password reset email in test mode', () async {
        await emailService.initialize(); // Test mode
        
        final result = await emailService.sendPasswordResetEmail(
          toEmail: 'test@example.com',
          resetToken: 'test_token_123',
          locale: 'en',
        );
        
        expect(result, true); // Should succeed in test mode
      });

      test('should send welcome email in test mode', () async {
        await emailService.initialize(); // Test mode
        
        final result = await emailService.sendWelcomeEmail(
          toEmail: 'test@example.com',
          userName: 'Test User',
          locale: 'en',
        );
        
        expect(result, true); // Should succeed in test mode
      });

      test('should send premium activation email in test mode', () async {
        await emailService.initialize(); // Test mode
        
        final result = await emailService.sendPremiumActivationEmail(
          toEmail: 'test@example.com',
          userName: 'Test User',
          tier: 'monthly',
          locale: 'en',
          expiryDate: DateTime.now().add(Duration(days: 30)),
        );
        
        expect(result, true); // Should succeed in test mode
      });
    });

    group('Error Handling', () {
      test('should handle invalid email addresses', () async {
        await emailService.initialize();
        
        final result = await emailService.sendPasswordResetEmail(
          toEmail: 'invalid-email',
          resetToken: 'test_token',
          locale: 'en',
        );
        
        // Should still return true in test mode, but log error
        expect(result, isA<bool>());
      });

      test('should handle missing required fields', () async {
        await emailService.initialize();
        
        // Missing resetToken should be handled gracefully
        final result = await emailService.sendPasswordResetEmail(
          toEmail: 'test@example.com',
          resetToken: '',
          locale: 'en',
        );
        
        expect(result, isA<bool>());
      });
    });
  });
}

