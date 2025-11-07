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
      final tierIndex = prefs.getInt(_tierKey) ?? 0;
      _currentTier = SubscriptionTier.values[tierIndex];
      
      // Load trial start
      final trialStartMs = prefs.getInt(_trialStartKey);
      _trialStartDate = trialStartMs != null ? DateTime.fromMillisecondsSinceEpoch(trialStartMs) : null;
      
      // Load subscription expiry
      final expiryMs = prefs.getInt(_subscriptionExpiryKey);
      _subscriptionExpiry = expiryMs != null ? DateTime.fromMillisecondsSinceEpoch(expiryMs) : null;
      
      // Load lifetime
      _isLifetime = prefs.getBool(_lifetimeKey) ?? false;
      
      // Auto-update tier if expired
      if (isSubscriptionExpired && _currentTier == SubscriptionTier.premium) {
        await setTier(SubscriptionTier.free);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PremiumService] Initialize error: $e');
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
}

