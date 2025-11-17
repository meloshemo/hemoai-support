import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_service.dart';

/// Premium/Subscription management service
/// Manages premium features, subscription tiers, and trial periods
enum SubscriptionTier {
  free,      // Free tier with basic features
  premium,   // Premium monthly/yearly subscription
  lifetime,  // One-time lifetime purchase
}

enum PremiumFeature {
  // Data & Sync
  unlimitedTests,           // Unlimited test entries (free: 10/month)
  cloudBackup,              // Automated cloud backups
  crossDeviceSync,          // Sync across multiple devices
  
  // AI & Analysis
  advancedAI,               // Advanced AI health insights
  predictiveAnalytics,      // Health trend predictions
  personalizedReports,      // Custom PDF reports
  
  // Family & Sharing
  unlimitedFamilyMembers,   // Unlimited family members (free: 2)
  familyHealthAI,           // AI insights for family members
  groupReports,             // Family group health reports
  
  // Notifications & Reminders
  smartReminders,           // AI-powered reminder optimization
  appointmentSync,          // Calendar integration
  medicationTracking,       // Advanced medication management
  
  // Export & Sharing
  advancedExports,          // Excel, PDF with charts
  bulkExport,               // Export all data at once
  customReports,            // Customizable report templates
  
  // Wellness & Diet
  unlimitedDietPlans,       // Unlimited diet plans (free: 1)
  mealPlanningAI,           // AI-powered meal suggestions
  macroTracking,            // Detailed macronutrient tracking
  groceryLists,             // Auto-generated shopping lists
  
  // Support & Priority
  prioritySupport,          // Email support response time
  featureRequests,          // Request new features
  betaAccess,               // Early access to new features
  
  // Alternative Medicine
  unlimitedRemedies,        // Unlimited alternative medicine suggestions
  ingredientAnalysis,       // Natural ingredient database
  herbalLibrary,            // Comprehensive herb library
  
  // Challenges & Motivation
  unlimitedChallenges,      // Unlimited group challenges (free: 1 active)
  createGroupChallenges,    // Create group challenges (free: can only join)
  advancedChallengeTypes,   // Combined, hemogram challenges (free: basic types only)
  challengeLeaderboards,    // Detailed leaderboards and stats
  challengeRewards,         // Badges and rewards system
  
  // Medical Consultation (Future feature - when doctors are integrated)
  expertDoctorConsultation, // Consult with expert doctors about test results
  doctorSecondOpinion,      // Get second opinion from specialists
  videoConsultation,        // Video call with doctors
  doctorPrescriptionReview, // Have doctors review prescriptions
  specialistReferral,       // Get referrals to specialists
}

class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _tierKey = 'premium_tier';
  static const String _trialStartKey = 'trial_start_date';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _lifetimeKey = 'lifetime_purchase';
  // Product IDs to align with payment and tests
  static const String productIdMonthly = 'hemoai_premium_monthly';
  static const String productIdYearly = 'hemoai_premium_yearly';
  static const String productIdLifetime = 'hemoai_premium_lifetime';
  
  SubscriptionTier _currentTier = SubscriptionTier.free;
  DateTime? _trialStartDate;
  DateTime? _subscriptionExpiry;
  bool _isLifetime = false;

  // Getters
  SubscriptionTier get currentTier => _currentTier;
  bool get isPremium => _currentTier == SubscriptionTier.premium || _isLifetime;
  bool get isFree => _currentTier == SubscriptionTier.free && !_isLifetime;
  bool get hasLifetime => _isLifetime;
  DateTime? get trialStartDate => _trialStartDate;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  
  // Check if trial is active
  bool get isTrialActive {
    if (_trialStartDate == null) return false;
    final daysSinceTrial = DateTime.now().difference(_trialStartDate!).inDays;
    return daysSinceTrial < 7; // 7-day trial
  }

  /// Activate premium based on a restored product ID (from store restore flow)
  Future<void> activateFromRestoredPurchase({required String productId}) async {
    if (productId == productIdLifetime) {
      await setTier(SubscriptionTier.lifetime, isLifetime: true);
      _subscriptionExpiry = null;
    } else if (productId == productIdYearly) {
      await setTier(SubscriptionTier.premium);
      await setSubscriptionExpiry(DateTime.now().add(const Duration(days: 365)));
    } else if (productId == productIdMonthly) {
      await setTier(SubscriptionTier.premium);
      await setSubscriptionExpiry(DateTime.now().add(const Duration(days: 30)));
    } else {
      // Unknown product, keep current tier
      debugPrint('[PremiumService] Unknown restored product: $productId');
    }
    notifyListeners();
  }
  
  // Check if subscription is expired
  bool get isSubscriptionExpired {
    if (_isLifetime) return false;
    if (_subscriptionExpiry == null) return _currentTier == SubscriptionTier.free;
    return DateTime.now().isAfter(_subscriptionExpiry!);
  }

  /// Initialize premium service and load saved state
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load tier
      // Support legacy string storage (tests may set string value)
      final dynamic rawTier = prefs.get(_tierKey);
      int tierIndex;
      if (rawTier is int) {
        tierIndex = rawTier;
      } else if (rawTier is String) {
        switch (rawTier) {
          case 'premium':
            tierIndex = SubscriptionTier.premium.index;
            break;
          case 'lifetime':
            tierIndex = SubscriptionTier.lifetime.index;
            break;
          default:
            tierIndex = SubscriptionTier.free.index;
        }
      } else {
        tierIndex = SubscriptionTier.free.index;
      }
      _currentTier = SubscriptionTier.values[tierIndex];
      
      // Load trial start (support legacy ISO8601 string)
      DateTime? trialDate;
      final dynamic rawTrial = prefs.get(_trialStartKey);
      if (rawTrial is int) {
        trialDate = DateTime.fromMillisecondsSinceEpoch(rawTrial);
      } else if (rawTrial is String) {
        try { trialDate = DateTime.parse(rawTrial); } catch (_) {}
      }
      _trialStartDate = trialDate;
      
      // Load subscription expiry (support legacy ISO8601 string)
      DateTime? expiryDate;
      final dynamic rawExpiry = prefs.get(_subscriptionExpiryKey);
      if (rawExpiry is int) {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(rawExpiry);
      } else if (rawExpiry is String) {
        try { expiryDate = DateTime.parse(rawExpiry); } catch (_) {}
      }
      _subscriptionExpiry = expiryDate;
      
      // Load lifetime
      _isLifetime = prefs.getBool(_lifetimeKey) ?? false;
      
      // Auto-update tier if expired
      if (isSubscriptionExpired && _currentTier == SubscriptionTier.premium) {
        await setTier(SubscriptionTier.free);
      }

      // Perform lightweight revalidation (can be expanded with server verification)
      // Ensures any inconsistent lifetime / expiry states are corrected at startup.
      await _revalidateIfNeeded(prefs);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PremiumService] Initialize error: $e');
    }
  }

  /// Public manual trigger for subscription revalidation (e.g., after login).
  Future<void> revalidateNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _revalidateIfNeeded(prefs, force: true);
    } catch (e) {
      debugPrint('[PremiumService] Revalidate error: $e');
    }
  }

  /// Internal revalidation logic.
  /// - If lifetime flag set but tier not lifetime, correct it.
  /// - If premium but expiry missing/past, downgrade to free.
  /// - If premium and expiry within 24h, could trigger proactive renewal check (placeholder).
  Future<void> _revalidateIfNeeded(SharedPreferences prefs, {bool force = false}) async {
    // Lifetime consistency check
    if (_isLifetime && _currentTier != SubscriptionTier.lifetime) {
      _currentTier = SubscriptionTier.lifetime;
      await prefs.setInt(_tierKey, SubscriptionTier.lifetime.index);
      notifyListeners();
    }

    if (_currentTier == SubscriptionTier.premium && !_isLifetime) {
      // Missing expiry should invalidate subscription
      if (_subscriptionExpiry == null) {
        await setTier(SubscriptionTier.free);
        return;
      }
      final now = DateTime.now();
      if (now.isAfter(_subscriptionExpiry!)) {
        await setTier(SubscriptionTier.free);
        return;
      }
      // Placeholder: if within 24h of expiry and force flag set, we could call a backend to refresh.
      if (force && _subscriptionExpiry!.difference(now) < const Duration(hours: 24)) {
        // Backend renewal/verification hook (future implementation)
        debugPrint('[PremiumService] Expiry within 24h - backend renewal check placeholder');
      }
    }
  }

  /// Set subscription tier
  Future<void> setTier(SubscriptionTier tier, {bool isLifetime = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _currentTier = tier;
      _isLifetime = isLifetime;
      
      await prefs.setInt(_tierKey, tier.index);
      await prefs.setBool(_lifetimeKey, isLifetime);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PremiumService] Set tier error: $e');
    }
  }

  /// Start 7-day free trial
  Future<void> startTrial() async {
    if (_trialStartDate != null) {
      debugPrint('[PremiumService] Trial already started');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _trialStartDate = DateTime.now();
      
      await prefs.setInt(_trialStartKey, _trialStartDate!.millisecondsSinceEpoch);
      await setTier(SubscriptionTier.premium);
      
      notifyListeners();
      debugPrint('[PremiumService] Trial started');
    } catch (e) {
      debugPrint('[PremiumService] Start trial error: $e');
    }
  }

  /// Set subscription expiry
  Future<void> setSubscriptionExpiry(DateTime expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _subscriptionExpiry = expiry;
      
      await prefs.setInt(_subscriptionExpiryKey, expiry.millisecondsSinceEpoch);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PremiumService] Set expiry error: $e');
    }
  }

  /// Check if user has access to a premium feature
  bool hasAccessTo(PremiumFeature feature) {
    if (_isLifetime) return true;
    if (_currentTier == SubscriptionTier.free && !isTrialActive) return false;
    // Add specific feature checks here
    return true; // Trial and premium users have full access for now
  }

  /// Get remaining trial days
  int get remainingTrialDays {
    if (!isTrialActive) return 0;
    final daysSinceTrial = DateTime.now().difference(_trialStartDate!).inDays;
    return 7 - daysSinceTrial;
  }

  /// Get subscription status text
  String getStatusText(LocalizationService loc) {
    if (_isLifetime) {
      return loc.getString('premium_lifetime');
    }
    
    if (isTrialActive) {
      return loc.getStringWithParams('premium_trial_days', {'days': remainingTrialDays.toString()});
    }
    
    if (isPremium && !isSubscriptionExpired) {
      return loc.getString('premium_active');
    }
    
    if (isSubscriptionExpired) {
      return loc.getString('premium_expired');
    }
    
    return loc.getString('premium_free');
  }

  /// Get feature availability info for a specific feature
  String getFeatureAvailability(PremiumFeature feature, LocalizationService loc) {
    if (hasAccessTo(feature)) {
      return loc.getString('available');
    }
    
    switch (feature) {
      case PremiumFeature.unlimitedTests:
        return loc.getString('free_limit_10_tests_month');
      case PremiumFeature.unlimitedFamilyMembers:
        return loc.getString('free_limit_2_members');
      case PremiumFeature.cloudBackup:
        return loc.getString('premium_feature');
      case PremiumFeature.advancedAI:
        return loc.getString('premium_feature');
      case PremiumFeature.unlimitedDietPlans:
        return loc.getString('free_limit_1_plan');
      default:
        return loc.getString('premium_feature');
    }
  }

  /// Upgrade to premium (simulated - integrate with payment gateway)
  Future<bool> upgradeToPremium({bool isYearly = false, bool lifetime = false}) async {
    try {
      // TODO: Integrate with in-app purchase or payment gateway
      // For now, simulate successful upgrade
      
      if (lifetime) {
        await setTier(SubscriptionTier.lifetime, isLifetime: true);
      } else {
        await setTier(SubscriptionTier.premium);
        final expiry = DateTime.now().add(Duration(days: isYearly ? 365 : 30));
        await setSubscriptionExpiry(expiry);
      }
      
      debugPrint('[PremiumService] Upgrade successful');
      return true;
    } catch (e) {
      debugPrint('[PremiumService] Upgrade error: $e');
      return false;
    }
  }

  /// Restore purchases (for iOS/Android)
  Future<bool> restorePurchases() async {
    try {
      // TODO: Integrate with in-app purchase restore
      await initialize(); // Reload state
      return true;
    } catch (e) {
      debugPrint('[PremiumService] Restore error: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      await setTier(SubscriptionTier.free);
      _subscriptionExpiry = null;
      _isLifetime = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionExpiryKey);
      await prefs.setBool(_lifetimeKey, false);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PremiumService] Cancel error: $e');
    }
  }

  /// Override dispose for singleton safety in tests (avoid disposed errors)
  @override
  void dispose() {
    super.dispose();
  }
}

