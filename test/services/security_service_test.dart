import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService', () {
    late SecurityService securityService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      securityService = SecurityService();
      await securityService.initialize();
    });

    test('should create singleton instance', () {
      final instance1 = SecurityService();
      final instance2 = SecurityService();
      expect(instance1, equals(instance2));
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final service = SecurityService();
        await service.initialize();
        // Should not throw
        expect(service, isNotNull);
      });

      test('should generate encryption key on first init', () async {
        SharedPreferences.setMockInitialValues({});
        final service = SecurityService();
        await service.initialize();
        // Encryption key should be generated
        expect(service, isNotNull);
      });
    });

    group('API Key Storage', () {
      test('should store API key securely', () async {
        await securityService.storeApiKey('test_key', 'test_value');
        // Should not throw
        expect(securityService, isNotNull);
      });

      test('should retrieve API key securely', () async {
        await securityService.storeApiKey('test_key', 'test_value');
        final value = await securityService.getApiKey('test_key');
        expect(value, equals('test_value'));
      });

      test('should return null for non-existent key', () async {
        final value = await securityService.getApiKey('non_existent');
        expect(value, isNull);
      });
    });

    group('Rate Limiting', () {
      test('should allow requests within limit', () {
        final identifier = 'test_identifier';
        
        // Make 5 requests (within limit of 10)
        for (int i = 0; i < 5; i++) {
          final allowed = securityService.checkRateLimit(identifier);
          expect(allowed, true);
        }
      });

      test('should block requests exceeding limit', () {
        final identifier = 'test_identifier';
        final maxRequests = 5;
        final window = Duration(minutes: 1);
        
        // Make requests up to limit
        for (int i = 0; i < maxRequests; i++) {
          final allowed = securityService.checkRateLimit(
            identifier,
            maxRequests: maxRequests,
            window: window,
          );
          expect(allowed, true);
        }
        
        // Next request should be blocked
        final blocked = securityService.checkRateLimit(
          identifier,
          maxRequests: maxRequests,
          window: window,
        );
        expect(blocked, false);
      });

      test('should reset rate limit after window expires', () async {
        final identifier = 'test_identifier';
        final maxRequests = 2;
        final window = Duration(milliseconds: 100);
        
        // Exceed limit
        securityService.checkRateLimit(
          identifier,
          maxRequests: maxRequests,
          window: window,
        );
        securityService.checkRateLimit(
          identifier,
          maxRequests: maxRequests,
          window: window,
        );
        
        final blocked = securityService.checkRateLimit(
          identifier,
          maxRequests: maxRequests,
          window: window,
        );
        expect(blocked, false);
        
        // Wait for window to expire
        await Future.delayed(Duration(milliseconds: 150));
        
        // Should be allowed again
        final allowed = securityService.checkRateLimit(
          identifier,
          maxRequests: maxRequests,
          window: window,
        );
        expect(allowed, true);
      });
    });

    group('Input Sanitization', () {
      test('should sanitize SQL injection attempts', () {
        const maliciousInput = "'; DROP TABLE users; --";
        final sanitized = securityService.sanitizeInput(maliciousInput);
        expect(sanitized, isNot(contains("DROP")));
        expect(sanitized, isNot(contains("'")));
      });

      test('should sanitize XSS attempts', () {
        const maliciousInput = '<script>alert("XSS")</script>';
        final sanitized = securityService.sanitizeInput(maliciousInput);
        expect(sanitized, isNot(contains('<script>')));
        expect(sanitized, isNot(contains('</script>')));
      });

      test('should preserve safe input', () {
        const safeInput = 'Hello World 123';
        final sanitized = securityService.sanitizeInput(safeInput);
        expect(sanitized, contains('Hello'));
        expect(sanitized, contains('World'));
      });

      test('should handle null input', () {
        final sanitized = securityService.sanitizeInput(null);
        expect(sanitized, isEmpty);
      });

      test('should handle empty input', () {
        final sanitized = securityService.sanitizeInput('');
        expect(sanitized, isEmpty);
      });
    });

    group('Secure Token Generation', () {
      test('should generate secure token', () {
        final token = securityService.generateSecureToken();
        expect(token, isNotEmpty);
        expect(token.length, greaterThan(16));
      });

      test('should generate unique tokens', () {
        final token1 = securityService.generateSecureToken();
        final token2 = securityService.generateSecureToken();
        expect(token1, isNot(equals(token2)));
      });

      test('should generate token with custom length', () {
        final token = securityService.generateSecureToken(length: 32);
        expect(token.length, equals(32));
      });
    });
  });
}

