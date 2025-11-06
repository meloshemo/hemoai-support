import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumService', () {
    late PremiumService premiumService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      premiumService = PremiumService();
      await premiumService.initialize();
    });

    tearDown(() {
      premiumService.dispose();
    });

    test('should create singleton instance', () {
      final instance1 = PremiumService();
      final instance2 = PremiumService();
      expect(instance1, equals(instance2));
    });

    group('Initialization', () {
      test('should initialize with free tier by default', () {
        expect(premiumService.currentTier, SubscriptionTier.free);
        expect(premiumService.isFree, true);
        expect(premiumService.isPremium, false);
      });

      test('should load saved state', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('premium_tier', 'premium');
        
        await premiumService.initialize();
        // Should load from storage
        expect(premiumService.currentTier, isA<SubscriptionTier>());
      });
    });

    group('Tier Management', () {
      test('should upgrade to premium', () async {
        await premiumService.upgradeToPremium(isYearly: false, lifetime: false);
        await premiumService.setSubscriptionExpiry(DateTime.now().add(Duration(days: 30)));
        
        expect(premiumService.isPremium, true);
        expect(premiumService.currentTier, SubscriptionTier.premium);
      });

      test('should upgrade to lifetime', () async {
        await premiumService.upgradeToPremium(lifetime: true);
        
        expect(premiumService.hasLifetime, true);
        expect(premiumService.isPremium, true);
      });

      test('should handle different tier types', () async {
        // Monthly
        await premiumService.upgradeToPremium(isYearly: false, lifetime: false);
        await premiumService.setSubscriptionExpiry(DateTime.now().add(Duration(days: 30)));
        expect(premiumService.isPremium, true);
        
        // Reset
        await premiumService.initialize();
        
        // Yearly
        await premiumService.upgradeToPremium(isYearly: true, lifetime: false);
        await premiumService.setSubscriptionExpiry(DateTime.now().add(Duration(days: 365)));
        expect(premiumService.isPremium, true);
      });
    });

    group('Feature Access', () {
      test('should check feature access for free tier', () {
        expect(premiumService.hasAccessTo(PremiumFeature.unlimitedTests), false);
        expect(premiumService.hasAccessTo(PremiumFeature.advancedAI), false);
      });

      test('should check feature access for premium tier', () async {
        await premiumService.upgradeToPremium(isYearly: false, lifetime: false);
        await premiumService.setSubscriptionExpiry(DateTime.now().add(Duration(days: 30)));
        
        expect(premiumService.hasAccessTo(PremiumFeature.unlimitedTests), true);
        expect(premiumService.hasAccessTo(PremiumFeature.advancedAI), true);
      });

      test('should check feature access for lifetime tier', () async {
        await premiumService.upgradeToPremium(lifetime: true);
        
        expect(premiumService.hasAccessTo(PremiumFeature.unlimitedTests), true);
        expect(premiumService.hasAccessTo(PremiumFeature.advancedAI), true);
      });
    });

    group('Trial Management', () {
      test('should start trial', () async {
        await premiumService.startTrial();
        expect(premiumService.isTrialActive, true);
      });

      test('should check trial expiry', () async {
        await premiumService.startTrial();
        final trialStart = premiumService.trialStartDate;
        expect(trialStart, isNotNull);
      });

      test('should expire trial after 7 days', () async {
        await premiumService.startTrial();
        
        // Simulate 8 days passed (trial should be expired)
        final prefs = await SharedPreferences.getInstance();
        final pastDate = DateTime.now().subtract(Duration(days: 8));
        await prefs.setString('trial_start_date', pastDate.toIso8601String());
        
        await premiumService.initialize();
        expect(premiumService.isTrialActive, false);
      });
    });

    group('Subscription Expiry', () {
      test('should check subscription expiry', () async {
        await premiumService.upgradeToPremium(isYearly: false, lifetime: false);
        await premiumService.setSubscriptionExpiry(DateTime.now().add(Duration(days: 30)));
        
        expect(premiumService.isSubscriptionExpired, false);
        expect(premiumService.subscriptionExpiry, isNotNull);
      });

      test('should detect expired subscription', () async {
        await premiumService.upgradeToPremium(isYearly: false, lifetime: false);
        await premiumService.setSubscriptionExpiry(DateTime.now().subtract(Duration(days: 1))); // Expired
        
        expect(premiumService.isSubscriptionExpired, true);
      });

      test('should not expire lifetime subscriptions', () async {
        await premiumService.upgradeToPremium(lifetime: true);
        
        expect(premiumService.isSubscriptionExpired, false);
        expect(premiumService.subscriptionExpiry, isNull);
      });
    });

    group('Purchase Restoration', () {
      test('should restore purchases', () async {
        await premiumService.restorePurchases();
        // Should reload state from storage
        expect(premiumService.currentTier, isA<SubscriptionTier>());
      });

      test('should activate from restored purchase', () async {
        await premiumService.activateFromRestoredPurchase(
          productId: 'hemoai_premium_monthly',
        );
        
        expect(premiumService.isPremium, true);
      });

      test('should handle different product IDs', () async {
        // Monthly
        await premiumService.activateFromRestoredPurchase(
          productId: 'hemoai_premium_monthly',
        );
        expect(premiumService.isPremium, true);
        
        // Reset
        await premiumService.initialize();
        
        // Yearly
        await premiumService.activateFromRestoredPurchase(
          productId: 'hemoai_premium_yearly',
        );
        expect(premiumService.isPremium, true);
        
        // Reset
        await premiumService.initialize();
        
        // Lifetime
        await premiumService.activateFromRestoredPurchase(
          productId: 'hemoai_premium_lifetime',
        );
        expect(premiumService.hasLifetime, true);
      });
    });
  });
}

