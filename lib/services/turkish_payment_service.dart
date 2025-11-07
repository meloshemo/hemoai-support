import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'premium_service.dart';
import 'currency_service.dart';
import 'localization_service.dart';
import 'dart:async';
import 'payment_service.dart';

/// Türkiye için ödeme servisi (İyzico/PayTR) ve mobil in-app purchase
/// Web ödemeleri için backend servisi üzerinden İyzico kullanılır
/// Mobil ödemeler için Google Play/App Store kullanılır (Türkiye'de destekleniyor)
class TurkishPaymentService implements IPaymentService {
  static final TurkishPaymentService _instance = TurkishPaymentService._internal();
  factory TurkishPaymentService() => _instance;
  TurkishPaymentService._internal();

  // Backend servisi URL'i (İyzico entegrasyonu için)
  // TODO: Kendi backend servisinizin URL'ini buraya ekleyin
  static const String _backendPaymentUrl = 'https://your-backend.com/api/payment/create';
  static const String _backendWebhookUrl = 'https://your-backend.com/api/webhook/iyzico';

  // In-App Purchase product IDs (Google Play ve App Store için)
  static const String _productIdMonthly = 'hemoai_premium_monthly';
  static const String _productIdYearly = 'hemoai_premium_yearly';
  static const String _productIdLifetime = 'hemoai_premium_lifetime';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;

  /// Initialize payment service
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web: Backend servisi üzerinden İyzico kullanılacak
      _isAvailable = true;
      return;
    }

    // Mobile: Initialize in-app purchase (Google Play / App Store)
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('[TurkishPaymentService] In-app purchase not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[TurkishPaymentService] Purchase stream error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  /// Load available products from store
  Future<void> _loadProducts() async {
    if (kIsWeb || !_isAvailable) return;

    final productIds = {
      _productIdMonthly,
      _productIdYearly,
      _productIdLifetime,
    };

    final response = await _inAppPurchase.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[TurkishPaymentService] Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    debugPrint('[TurkishPaymentService] Loaded ${_products.length} products');
  }

  /// Handle purchase updates (Mobile only)
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _purchasePending = true;
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        debugPrint('[TurkishPaymentService] Purchase error: ${purchase.error}');
        _purchasePending = false;
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        await _verifyAndActivatePremium(purchase);
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }

      _purchasePending = false;
    }
  }

  /// Verify purchase and activate premium
  Future<void> _verifyAndActivatePremium(PurchaseDetails purchase) async {
    try {
      final productId = purchase.productID;
      final premiumService = PremiumService();

      if (productId == _productIdLifetime) {
        await premiumService.setTier(SubscriptionTier.lifetime, isLifetime: true);
        debugPrint('[TurkishPaymentService] Lifetime premium activated');
      } else if (productId == _productIdYearly) {
        await premiumService.setTier(SubscriptionTier.premium);
        final expiry = DateTime.now().add(const Duration(days: 365));
        await premiumService.setSubscriptionExpiry(expiry);
        debugPrint('[TurkishPaymentService] Yearly premium activated until $expiry');
      } else if (productId == _productIdMonthly) {
        await premiumService.setTier(SubscriptionTier.premium);
        final expiry = DateTime.now().add(const Duration(days: 30));
        await premiumService.setSubscriptionExpiry(expiry);
        debugPrint('[TurkishPaymentService] Monthly premium activated until $expiry');
      }

      // Store purchase receipt
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_purchase_id', purchase.purchaseID ?? '');
      await prefs.setString('last_purchase_product_id', productId);
    } catch (e) {
      debugPrint('[TurkishPaymentService] Verify purchase error: $e');
    }
  }

  /// Purchase premium (mobile: in-app purchase, web: İyzico via backend)
  Future<bool> purchasePremium({
    required BuildContext context,
    required bool isYearly,
    required bool isLifetime,
    String? userEmail,
    String? userName,
  }) async {
    if (kIsWeb) {
      // Web: Backend servisi üzerinden İyzico ödeme sayfasına yönlendir
      return await _purchasePremiumWeb(
        context, 
        isYearly: isYearly, 
        isLifetime: isLifetime,
        userEmail: userEmail,
        userName: userName,
      );
    } else {
      // Mobile: In-app purchase
      return await _purchasePremiumMobile(isYearly: isYearly, isLifetime: isLifetime);
    }
  }

  /// Purchase premium via İyzico (web) - Backend servisi üzerinden
  Future<bool> _purchasePremiumWeb(
    BuildContext context, {
    required bool isYearly,
    required bool isLifetime,
    String? userEmail,
    String? userName,
  }) async {
    try {
      // Plan tipi belirle
      final planType = isLifetime ? 'lifetime' : (isYearly ? 'yearly' : 'monthly');
      final price = isLifetime ? 999.99 : (isYearly ? 399.99 : 49.99); // TRY fiyatlar

      // Backend servisine ödeme isteği gönder
      // Backend, İyzico'ya istek gönderir ve ödeme sayfası URL'i döner
      if (kDebugMode && _backendPaymentUrl.contains('your-backend')) {
        // Test modunda, backend yoksa bilgilendirme göster
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('İyzico Entegrasyonu Gerekli'),
            content: const Text(
              'Web ödemeleri için backend servisi kurulumu gereklidir:\n\n'
              '1. İyzico hesabı oluşturun (iyzico.com)\n'
              '2. Backend servisi kurun (Node.js/Python/Dart)\n'
              '3. İyzico API entegrasyonu yapın\n'
              '4. Backend URL\'ini TurkishPaymentService\'e ekleyin\n'
              '5. Webhook endpoint oluşturun\n\n'
              'Detaylı bilgi için: docs/TURKISH_PAYMENT_INTEGRATION.md\n\n'
              'Şimdilik test modunda premium aktifleştiriliyor.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );

        // Test modunda premium'u aktif et
        final premiumService = PremiumService();
        if (isLifetime) {
          await premiumService.setTier(SubscriptionTier.lifetime, isLifetime: true);
        } else {
          await premiumService.setTier(SubscriptionTier.premium);
          final expiry = DateTime.now().add(Duration(days: isYearly ? 365 : 30));
          await premiumService.setSubscriptionExpiry(expiry);
        }
        return true;
      }

      // Gerçek backend isteği (backend kurulduğunda)
      final response = await http.post(
        Uri.parse(_backendPaymentUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'plan_type': planType,
          'price': price,
          'currency': 'TRY',
          'user_email': userEmail,
          'user_name': userName,
          'return_url': 'https://your-app.com/payment-success',
          'callback_url': _backendWebhookUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['payment_url'] as String?;
        
        if (paymentUrl != null) {
          // İyzico ödeme sayfasına yönlendir
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            // Webhook ile premium durumu güncellenecek
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('[TurkishPaymentService] Web purchase error: $e');
      return false;
    }
  }

  /// Purchase premium via in-app purchase (mobile)
  Future<bool> _purchasePremiumMobile({
    required bool isYearly,
    required bool isLifetime,
  }) async {
    if (!_isAvailable || _purchasePending) {
      debugPrint('[TurkishPaymentService] Purchase not available or pending');
      return false;
    }

    try {
      String productId;
      if (isLifetime) {
        productId = _productIdLifetime;
      } else if (isYearly) {
        productId = _productIdYearly;
      } else {
        productId = _productIdMonthly;
      }

      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      final purchaseParam = PurchaseParam(productDetails: product);
      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (success) {
        _purchasePending = true;
        debugPrint('[TurkishPaymentService] Purchase initiated: $productId');
      }
      
      return success;
    } catch (e) {
      debugPrint('[TurkishPaymentService] Mobile purchase error: $e');
      return false;
    }
  }

  /// Restore purchases (mobile only)
  Future<bool> restorePurchases() async {
    if (kIsWeb) {
      // Web: Backend'den kontrol edilmeli
      return false;
    }

    if (!_isAvailable) return false;

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('[TurkishPaymentService] Restore purchases initiated');
      return true;
    } catch (e) {
      debugPrint('[TurkishPaymentService] Restore purchases error: $e');
      return false;
    }
  }

  /// Get product price for display
  String? getProductPrice({required bool isYearly, required bool isLifetime, String? languageCode}) {
    final loc = LocalizationService();
    final lang = languageCode ?? loc.currentLanguageCode;
    final currencyService = CurrencyService();
    
    if (kIsWeb) {
      // Web: Use currency service for dynamic pricing
      if (isLifetime) return currencyService.getLifetimePrice(lang);
      if (isYearly) return currencyService.getYearlyPrice(lang);
      return currencyService.getMonthlyPrice(lang);
    }

    try {
      String productId;
      if (isLifetime) {
        productId = _productIdLifetime;
      } else if (isYearly) {
        productId = _productIdYearly;
      } else {
        productId = _productIdMonthly;
      }

      final product = _products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (e) {
      debugPrint('[TurkishPaymentService] Get price error: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
}

