import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'premium_service.dart';
import 'localization_service.dart';
import 'email_service.dart';

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

  // Note: Stripe integration removed - using only Google Play and App Store

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
      // Web: Premium not available on web platform
      _isAvailable = false;
      debugPrint('[PaymentService] Premium subscriptions are only available on mobile platforms');
      return;
    }

    // Mobile: Initialize in-app purchase (Google Play / App Store)
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
        
        // For restored purchases, also update PremiumService with purchase details
        if (purchase.status == PurchaseStatus.restored) {
          final premiumService = PremiumService();
          await premiumService.activateFromRestoredPurchase(
            productId: purchase.productID,
            purchaseId: purchase.purchaseID ?? '',
          );
        }
        
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

      DateTime? expiryDate;
      String tier = 'monthly';
      
      if (productId == _productIdLifetime) {
        await premiumService.setTier(SubscriptionTier.lifetime, isLifetime: true);
        tier = 'lifetime';
        debugPrint('[PaymentService] Lifetime premium activated');
      } else if (productId == _productIdYearly) {
        await premiumService.setTier(SubscriptionTier.premium);
        expiryDate = DateTime.now().add(const Duration(days: 365));
        await premiumService.setSubscriptionExpiry(expiryDate);
        tier = 'yearly';
        debugPrint('[PaymentService] Yearly premium activated until $expiryDate');
      } else if (productId == _productIdMonthly) {
        await premiumService.setTier(SubscriptionTier.premium);
        expiryDate = DateTime.now().add(const Duration(days: 30));
        await premiumService.setSubscriptionExpiry(expiryDate);
        tier = 'monthly';
        debugPrint('[PaymentService] Monthly premium activated until $expiryDate');
      }

      // Send premium activation email
      try {
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email');
        final userName = prefs.getString('user_name') ?? 'User';
        final locale = prefs.getString('selected_language') ?? 'en';
        
        if (userEmail != null && userEmail.isNotEmpty) {
          final emailService = EmailService();
          await emailService.sendPremiumActivationEmail(
            toEmail: userEmail,
            userName: userName,
            tier: tier,
            locale: locale.length >= 2 ? locale.substring(0, 2) : 'en',
            expiryDate: expiryDate,
          );
        }
      } catch (e) {
        debugPrint('[PaymentService] Premium activation email error (non-critical): $e');
      }

      // Store purchase receipt for server-side verification (optional)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_purchase_id', purchase.purchaseID ?? '');
      await prefs.setString('last_purchase_product_id', productId);
    } catch (e) {
      debugPrint('[PaymentService] Verify purchase error: $e');
    }
  }

  /// Purchase premium (mobile: in-app purchase only)
  /// Note: Premium subscriptions are only available on mobile platforms (Android/iOS)
  Future<bool> purchasePremium({
    required BuildContext context,
    required bool isYearly,
    required bool isLifetime,
    String? userEmail,
    String? userName,
  }) async {
    if (kIsWeb) {
      // Web: Premium is not available, show message to user
      final loc = LocalizationService();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('premium_web_not_available') ?? 'Premium özellikler sadece mobil uygulamalarda mevcuttur. Lütfen Android veya iOS uygulamasını indirin.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: loc.getString('ok') ?? 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      }
      return false;
    } else {
      // Mobile: In-app purchase via Google Play / App Store
      return await _purchasePremiumMobile(isYearly: isYearly, isLifetime: isLifetime);
    }
  }

  // Stripe integration removed - premium is only available on mobile platforms

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
  /// This will trigger the purchase stream which will restore any previous purchases
  Future<bool> restorePurchases() async {
    if (kIsWeb) {
      // Web: Premium not available on web platform
      debugPrint('[PaymentService] Premium subscriptions are only available on mobile platforms');
      return false;
    }

    if (!_isAvailable) {
      debugPrint('[PaymentService] In-app purchase not available for restore');
      return false;
    }

    try {
      // Restore purchases will trigger the purchase stream
      // The stream listener (_onPurchaseUpdate) will handle restored purchases
      await _inAppPurchase.restorePurchases();
      debugPrint('[PaymentService] Restore purchases initiated - listening for restored purchases');
      
      // Also reload PremiumService state
      final premiumService = PremiumService();
      await premiumService.restorePurchases();
      
      return true;
    } catch (e) {
      debugPrint('[PaymentService] Restore purchases error: $e');
      return false;
    }
  }

  /// Get product price for display (mobile only)
  String? getProductPrice({required bool isYearly, required bool isLifetime, String? languageCode}) {
    if (kIsWeb) {
      // Web: Premium not available
      return null;
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

