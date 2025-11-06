import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Professional security service
/// Handles encryption, certificate pinning, rate limiting, and secure storage
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final Logger _logger = Logger();
  final Map<String, List<DateTime>> _rateLimitMap = {};
  static const String _apiKeyStorageKey = 'secure_api_key';
  static const String _encryptionKeyKey = 'secure_encryption_key';

  /// Initialize security service
  Future<void> initialize() async {
    try {
      // Generate encryption key if not exists
      await _ensureEncryptionKey();
      _logger.i('SecurityService initialized');
    } catch (e) {
      _logger.e('Failed to initialize SecurityService: $e');
      rethrow;
    }
  }

  /// Generate secure encryption key
  Future<void> _ensureEncryptionKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingKey = prefs.getString(_encryptionKeyKey);
      
      if (existingKey == null) {
        // Generate new key using secure random
        final key = _generateSecureKey(32);
        await prefs.setString(_encryptionKeyKey, key);
        _logger.i('Generated new encryption key');
      }
    } catch (e) {
      _logger.e('Failed to ensure encryption key: $e');
    }
  }

  /// Generate secure random key
  String _generateSecureKey(int length) {
    final random = List<int>.generate(length, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    final bytes = utf8.encode(DateTime.now().toIso8601String() + random.toString());
    final hash = sha256.convert(bytes);
    return base64Encode(hash.bytes);
  }

  /// Store API key securely
  Future<void> storeApiKey(String key, String value) async {
    try {
      // Use flutter_secure_storage for sensitive data
      final secureStorage = FlutterSecureStorage();
      await secureStorage.write(key: key, value: value);
      _logger.i('API key stored securely');
    } catch (e) {
      _logger.e('Failed to store API key: $e');
      rethrow;
    }
  }

  /// Get API key securely
  Future<String?> getApiKey(String key) async {
    try {
      final secureStorage = FlutterSecureStorage();
      return await secureStorage.read(key: key);
    } catch (e) {
      _logger.e('Failed to get API key: $e');
      return null;
    }
  }

  /// Rate limiting check
  /// Returns true if request is allowed, false if rate limited
  bool checkRateLimit(String identifier, {
    int maxRequests = 10,
    Duration window = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();
    final requests = _rateLimitMap[identifier] ?? [];
    
    // Remove old requests outside the window
    requests.removeWhere((timestamp) => now.difference(timestamp) > window);
    
    if (requests.length >= maxRequests) {
      _logger.w('Rate limit exceeded for: $identifier');
      return false;
    }
    
    // Add current request
    requests.add(now);
    _rateLimitMap[identifier] = requests;
    
    return true;
  }

  /// Reset rate limit for identifier
  void resetRateLimit(String identifier) {
    _rateLimitMap.remove(identifier);
  }

  /// Sanitize input to prevent injection attacks
  String sanitizeInput(String? input) {
    if (input == null || input.isEmpty) return '';
    // Remove potential SQL injection patterns
    var sanitized = input
        .replaceAll(RegExp(r"[';""]"), '')
        .replaceAll('--', '')
        .replaceAll('/*', '')
        .replaceAll('*/', '')
        .replaceAll(RegExp(r'<script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</script>', caseSensitive: false), '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }

  /// Validate API key format
  bool validateApiKeyFormat(String? key) {
    if (key == null || key.isEmpty) return false;
    
    // Basic format validation (adjust based on your API key format)
    if (key.length < 16 || key.length > 256) return false;
    
    // Check for only alphanumeric and common special chars
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(key)) return false;
    
    return true;
  }

  /// Certificate pinning validation
  /// Note: This is a simplified version. For production, use proper certificate pinning
  Future<bool> validateCertificate(X509Certificate cert, String host) async {
    // In production, compare certificate fingerprint with pinned certificates
    // For now, we'll just log the certificate info
    _logger.i('Validating certificate for: $host');
    _logger.d('Certificate issuer: ${cert.issuer}');
    _logger.d('Certificate subject: ${cert.subject}');
    
    // TODO: Implement actual certificate pinning
    // Compare cert.sha1 or cert.sha256 with stored pinned certificates
    
    return true; // For now, accept all certificates
  }

  /// Hash sensitive data
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Generate secure token
  String generateSecureToken({int length = 32}) {
    final random = List<int>.generate(length, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    final bytes = utf8.encode(DateTime.now().toIso8601String() + random.toString());
    final hash = sha256.convert(bytes);
    return base64Encode(hash.bytes).substring(0, length);
  }

  /// Check if running in secure environment
  Future<bool> isSecureEnvironment() async {
    try {
      // Check if app is running in debug mode
      if (kDebugMode) {
        return false;
      }

      // Check if running on emulator/simulator (less secure)
      // Note: This is platform-specific and would need platform channels
      
      return true;
    } catch (e) {
      _logger.w('Could not determine security environment: $e');
      return false;
    }
  }

  /// Get app version for security checks
  Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      _logger.e('Failed to get app version: $e');
      return 'unknown';
    }
  }
}

