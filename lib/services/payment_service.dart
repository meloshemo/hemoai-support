import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_service.dart';
import 'currency_service.dart';
import 'localization_service.dart';
import 'dart:async';

/// Payment service for handling in-app purchases (Android/iOS) and web payments
/// Note: For Turkey, use TurkishPaymentService instead (uses İyzico instead of Stripe)
/// This service is kept for international users
abstract class IPaymentService {
  Future<void> initialize();
  Future<bool> purchasePremium({
    required BuildContext context,
    required bool isYearly,
    required bool isLifetime,
    String? userEmail,
    String? userName,
  });
  Future<bool> restorePurchases();
  String? getProductPrice({required bool isYearly, required bool isLifetime, String? languageCode});
  void dispose();
  bool get isAvailable;
  bool get purchasePending;
}

class PaymentService implements IPaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static const String _stripeMonthlyUrl = 'https://buy.stripe.com/monthly'; // TODO: Replace with real Stripe Checkout URL
  static const String _stripeYearlyUrl = 'https://buy.stripe.com/yearly';
  static const String _stripeLifetimeUrl = 'https://buy.stripe.com/lifetime';

  // In-App Purchase product IDs (configure in Google Play Console & App Store Connect)
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
      // Web: Stripe Checkout will be used
      _isAvailable = true;
      return;
    }

    // Mobile: Initialize in-app purchase
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('[PaymentService] In-app purchase not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[PaymentService] Purchase stream error: $error'),
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
      debugPrint('[PaymentService] Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    debugPrint('[PaymentService] Loaded ${_products.length} products');
  }

  /// Handle purchase updates
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _purchasePending = true;
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        debugPrint('[PaymentService] Purchase error: ${purchase.error}');
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
        debugPrint('[PaymentService] Lifetime premium activated');
      } else if (productId == _productIdYearly) {
        await premiumService.setTier(SubscriptionTier.premium);
        final expiry = DateTime.now().add(const Duration(days: 365));
        await premiumService.setSubscriptionExpiry(expiry);
        debugPrint('[PaymentService] Yearly premium activated until $expiry');
      } else if (productId == _productIdMonthly) {
        await premiumService.setTier(SubscriptionTier.premium);
        final expiry = DateTime.now().add(const Duration(days: 30));
        await premiumService.setSubscriptionExpiry(expiry);
        debugPrint('[PaymentService] Monthly premium activated until $expiry');
      }

      // Store purchase receipt for server-side verification (optional)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_purchase_id', purchase.purchaseID ?? '');
      await prefs.setString('last_purchase_product_id', productId);
    } catch (e) {
      debugPrint('[PaymentService] Verify purchase error: $e');
    }
  }

  /// Purchase premium (mobile: in-app purchase, web: Stripe)
  Future<bool> purchasePremium({
    required BuildContext context,
    required bool isYearly,
    required bool isLifetime,
    String? userEmail,
    String? userName,
  }) async {
    if (kIsWeb) {
      // Web: Open Stripe Checkout
      return await _purchasePremiumWeb(context, isYearly: isYearly, isLifetime: isLifetime);
    } else {
      // Mobile: In-app purchase
      return await _purchasePremiumMobile(isYearly: isYearly, isLifetime: isLifetime);
    }
  }

  /// Purchase premium via Stripe Checkout (web)
  Future<bool> _purchasePremiumWeb(
    BuildContext context, {
    required bool isYearly,
    required bool isLifetime,
  }) async {
    try {
      String url;
      if (isLifetime) {
        url = _stripeLifetimeUrl;
      } else if (isYearly) {
        url = _stripeYearlyUrl;
      } else {
        url = _stripeMonthlyUrl;
      }

      // TODO: Replace with actual Stripe Checkout URLs
      // For now, show a dialog explaining the setup needed
      if (kDebugMode) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Stripe Integration Required'),
            content: Text(
              'To enable web payments, configure Stripe Checkout:\n\n'
              '1. Create Stripe account\n'
              '2. Set up Checkout URLs for monthly/yearly/lifetime\n'
              '3. Configure webhook to verify payments\n'
              '4. Update PaymentService with your URLs\n\n'
              'URL would open: $url',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Simulate successful purchase for testing
      // TODO: Remove this after Stripe integration
      if (kDebugMode) {
        await Future.delayed(const Duration(seconds: 2));
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

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        
        // After Stripe payment, webhook should update user's premium status
        // For now, return false and wait for webhook confirmation
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('[PaymentService] Web purchase error: $e');
      return false;
    }
  }

  /// Purchase premium via in-app purchase (mobile)
  Future<bool> _purchasePremiumMobile({
    required bool isYearly,
    required bool isLifetime,
  }) async {
    if (!_isAvailable || _purchasePending) {
      debugPrint('[PaymentService] Purchase not available or pending');
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
        debugPrint('[PaymentService] Purchase initiated: $productId');
      }
      
      return success;
    } catch (e) {
      debugPrint('[PaymentService] Mobile purchase error: $e');
      return false;
    }
  }

  /// Restore purchases (mobile only)
  Future<bool> restorePurchases() async {
    if (kIsWeb) {
      // Web: Stripe purchases should be verified server-side
      return false;
    }

    if (!_isAvailable) return false;

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('[PaymentService] Restore purchases initiated');
      return true;
    } catch (e) {
      debugPrint('[PaymentService] Restore purchases error: $e');
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
      debugPrint('[PaymentService] Get price error: $e');
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

