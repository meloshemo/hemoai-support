// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/premium_service.dart';
import '../services/payment_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  IPaymentService? _paymentService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
  }

  void _initializePaymentService() {
    _paymentService = PaymentService();
    _paymentService?.initialize();
  }

  @override
  void dispose() {
    _paymentService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      drawer: const AppDrawer(currentRoute: '/premium'),
      appBar: UnifiedAppBar(
        title: loc.getString('premium'),
        currentRoute: '/premium',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!kIsWeb && _paymentService != null && !_paymentService!.isAvailable) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.getString('iap_not_available'),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Current Status Card
            _buildStatusCard(premiumService, loc, isDark),
            const SizedBox(height: 24),

            // Features Comparison
            Text(
              loc.getString('premium_features'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Feature List
            ..._buildFeatureList(premiumService, loc, isDark),
            const SizedBox(height: 32),

            // Pricing Plans
            Text(
              loc.getString('pricing_plans'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Premium Plans
            _buildPricingPlans(premiumService, loc, isDark),
            const SizedBox(height: 24),

            // Restore & Manage buttons (Mobile only)
            if (!kIsWeb) ...[
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _isProcessing ? null : () => _restorePurchases(context, loc),
                      icon: const Icon(Icons.restore),
                      label: Text(loc.getString('restore_purchases')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _openManageSubscription,
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: Text(loc.getString('manage_subscription')),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Subscription Terms / Auto-renewal disclaimer
            _buildSubscriptionTerms(loc, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(PremiumService premiumService, LocalizationService loc, bool isDark) {
    final statusText = premiumService.getStatusText(loc);
    final isPremium = premiumService.isPremium;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium 
              ? [const Color(0xFFE53E3E), const Color(0xFFC62828)]
              : [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.star_border,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (premiumService.isTrialActive) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: premiumService.remainingTrialDays / 7.0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${premiumService.remainingTrialDays} ${loc.getString("days")}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList(PremiumService premiumService, LocalizationService loc, bool isDark) {
    final features = [
      {
        'icon': Icons.cloud,
        'key': 'unlimited_tests',
        'feature': PremiumFeature.unlimitedTests,
      },
      {
        'icon': Icons.backup,
        'key': 'cloud_backup',
        'feature': PremiumFeature.cloudBackup,
      },
      {
        'icon': Icons.psychology,
        'key': 'advanced_ai',
        'feature': PremiumFeature.advancedAI,
      },
      {
        'icon': Icons.family_restroom,
        'key': 'unlimited_family',
        'feature': PremiumFeature.unlimitedFamilyMembers,
      },
      {
        'icon': Icons.restaurant_menu,
        'key': 'unlimited_diets',
        'feature': PremiumFeature.unlimitedDietPlans,
      },
      {
        'icon': Icons.analytics,
        'key': 'advanced_analytics',
        'feature': PremiumFeature.predictiveAnalytics,
      },
      {
        'icon': Icons.medical_services,
        'key': 'expert_doctor_consultation',
        'feature': PremiumFeature.expertDoctorConsultation,
        'highlight': true,
      },
      {
        'icon': Icons.video_call,
        'key': 'video_consultation',
        'feature': PremiumFeature.videoConsultation,
        'highlight': true,
      },
      {
        'icon': Icons.rate_review,
        'key': 'second_opinion',
        'feature': PremiumFeature.doctorSecondOpinion,
        'highlight': true,
      },
    ];

    return features.map((feature) {
      final matchedFeature = feature['feature'] as PremiumFeature? ?? PremiumFeature.cloudBackup;
      final hasAccess = premiumService.hasAccessTo(matchedFeature);

      final isHighlighted = feature['highlight'] == true;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFE53E3E).withValues(alpha: 0.8)
                : hasAccess 
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
            width: isHighlighted ? 2 : 1,
          ),
          gradient: isHighlighted && !hasAccess
              ? LinearGradient(
                  colors: [
                    (isDark ? const Color(0xFF161B22) : Colors.white),
                    (isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFFEBEE)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color(0xFFE53E3E).withValues(alpha: 0.1)
                    : hasAccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: isHighlighted
                    ? const Color(0xFFE53E3E)
                    : hasAccess 
                        ? Colors.green 
                        : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                loc.getString(feature['key'] as String),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isHighlighted && !hasAccess)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loc.getString('soon_badge'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                hasAccess ? Icons.check_circle : Icons.lock,
                color: hasAccess ? Colors.green : Colors.grey,
                size: 20,
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPricingPlans(PremiumService premiumService, LocalizationService loc, bool isDark) {
    return Column(
      children: [
        // Monthly
        _buildPlanCard(
          title: loc.getString('plan_monthly'),
          price: _paymentService?.getProductPrice(isYearly: false, isLifetime: false, languageCode: loc.currentLanguageCode) ?? 
                 ('\$4.99'),
          period: loc.getString('per_month'),
          isPopular: false,
          isDark: isDark,
          onTap: () => _handlePurchase(context, premiumService, loc, isYearly: false, isLifetime: false),
        ),
        const SizedBox(height: 12),
        // Yearly
        _buildPlanCard(
          title: loc.getString('plan_yearly'),
          price: _paymentService?.getProductPrice(isYearly: true, isLifetime: false, languageCode: loc.currentLanguageCode) ?? 
                 ('\$39.99'),
          period: loc.getString('per_year'),
          isPopular: true,
          isDark: isDark,
          onTap: () => _handlePurchase(context, premiumService, loc, isYearly: true, isLifetime: false),
        ),
        const SizedBox(height: 12),
        // Lifetime
        _buildPlanCard(
          title: loc.getString('plan_lifetime'),
          price: _paymentService?.getProductPrice(isYearly: false, isLifetime: true, languageCode: loc.currentLanguageCode) ?? 
                 ('\$99.99'),
          period: loc.getString('one_time'),
          isPopular: false,
          isDark: isDark,
          onTap: () => _handlePurchase(context, premiumService, loc, isYearly: false, isLifetime: true),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required bool isPopular,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular 
              ? const Color(0xFFE53E3E)
              : Colors.grey.withValues(alpha: 0.3),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (_, loc, __) => Text(
                            loc.getString('popular_badge'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isPopular) const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE53E3E),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    PremiumService premiumService,
    LocalizationService loc,
    {required bool isYearly, required bool isLifetime}
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Kullanıcı bilgilerini al (web ödemeleri için gerekli)
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('current_user_email');
      final userName = prefs.getString('current_user_name');
      
      if (_paymentService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('payment_service_not_initialized')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      final success = await _paymentService!.purchasePremium(
        context: context,
        isYearly: isYearly,
        isLifetime: isLifetime,
        userEmail: userEmail,
        userName: userName,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.getString('premium_activated'),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (_paymentService != null && !_paymentService!.purchasePending) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.getString('payment_initiation_failed'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('error_label')}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context, LocalizationService loc) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_paymentService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('payment_service_not_initialized')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      final success = await _paymentService!.restorePurchases();
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? loc.getString('purchases_restored_success')
              : loc.getString('no_purchases_to_restore')),
          backgroundColor: success ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('error_label')}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildSubscriptionTerms(LocalizationService loc, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.getString('subscription_terms_title'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.getString('subscription_terms_disclaimer'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManageSubscription() async {
    final platform = Theme.of(context).platform;
    Uri? uri;
    if (platform == TargetPlatform.android) {
      const packageName = 'com.meloshemo.hemoai';
      uri = Uri.parse('https://play.google.com/store/account/subscriptions?package=$packageName');
    } else if (platform == TargetPlatform.iOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    }
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    }
  }
}


