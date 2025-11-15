import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a server-side purchase verification.
class VerifiedPurchaseResult {
  final bool valid;
  final String tier; // 'monthly' | 'yearly' | 'lifetime'
  final DateTime? expiry; // null for lifetime

  const VerifiedPurchaseResult({
    required this.valid,
    required this.tier,
    this.expiry,
  });

  factory VerifiedPurchaseResult.invalid() => const VerifiedPurchaseResult(
        valid: false,
        tier: 'free',
      );
}

/// Service responsible for sending receipts/tokens to backend for validation
/// and translating the response into app subscription state.
class PurchaseVerificationService {
  static final PurchaseVerificationService _instance =
      PurchaseVerificationService._internal();
  factory PurchaseVerificationService() => _instance;
  PurchaseVerificationService._internal();

  // Configure via --dart-define or fall back to null to use local fallback
  static const String _defaultVerifyUrl =
      String.fromEnvironment('PURCHASE_VERIFY_URL', defaultValue: '');

  Uri? _verificationEndpoint() {
    final url = _defaultVerifyUrl.trim();
    if (url.isEmpty) return null;
    try {
      return Uri.parse(url);
    } catch (_) {
      return null;
    }
  }

  /// Verify a transaction with backend. The payload is platform-specific.
  ///
  /// platform: 'android' | 'ios'
  /// productId: Store product identifier
  /// token: Google Play purchaseToken (android) or App Store transaction/receipt data (ios)
  /// appAccountId: optional identifier linking store account to app user
  /// userEmail: optional for server correlation
  Future<VerifiedPurchaseResult> verifyReceipt({
    required String platform,
    required String productId,
    required String token,
    String? appAccountId,
    String? userEmail,
  }) async {
    final endpoint = _verificationEndpoint();

    // In tests or when no backend configured, perform optimistic local mapping
    if (endpoint == null) {
      if (kDebugMode) {
        debugPrint('[Verify] No backend configured; returning optimistic result');
      }
      final now = DateTime.now();
      if (productId.contains('lifetime')) {
        return const VerifiedPurchaseResult(valid: true, tier: 'lifetime');
      } else if (productId.contains('year')) {
        return VerifiedPurchaseResult(
          valid: true,
          tier: 'yearly',
          expiry: now.add(const Duration(days: 365)),
        );
      } else {
        return VerifiedPurchaseResult(
          valid: true,
          tier: 'monthly',
          expiry: now.add(const Duration(days: 30)),
        );
      }
    }

    try {
      final payload = {
        'platform': platform,
        'productId': productId,
        'token': token,
        if (appAccountId != null) 'appAccountId': appAccountId,
        if (userEmail != null) 'userEmail': userEmail,
      };

      final resp = await http
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('[Verify] Server responded ${resp.statusCode}: ${resp.body}');
        }
        return VerifiedPurchaseResult.invalid();
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final valid = data['valid'] == true;
      if (!valid) return VerifiedPurchaseResult.invalid();
      final tier = (data['tier'] as String?) ?? 'monthly';
      final expiryStr = data['expiry'] as String?;
      final expiry = expiryStr != null && expiryStr.isNotEmpty
          ? DateTime.tryParse(expiryStr)
          : null;
      return VerifiedPurchaseResult(valid: true, tier: tier, expiry: expiry);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Verify] Exception during verification: $e');
      }
      return VerifiedPurchaseResult.invalid();
    }
  }
}
