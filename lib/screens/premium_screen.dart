import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/premium_service.dart';
import '../services/payment_service.dart';
import '../services/turkish_payment_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';

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
    // Türkiye için TurkishPaymentService, diğer ülkeler için PaymentService
    final loc = LocalizationService();
    final isTurkey = loc.currentLanguageCode == 'tr';
    
    if (isTurkey) {
      _paymentService = TurkishPaymentService();
    } else {
      _paymentService = PaymentService();
    }
    
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
        title: loc.getString('premium') == 'premium' ? 'Premium' : loc.getString('premium'),
        currentRoute: '/premium',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            _buildStatusCard(premiumService, loc, isDark),
            const SizedBox(height: 24),

            // Features Comparison
            Text(
              loc.getString('premium_features') == 'premium_features' 
                  ? 'Premium Özellikler' 
                  : loc.getString('premium_features'),
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
              loc.getString('pricing_plans') == 'pricing_plans' 
                  ? 'Fiyatlandırma' 
                  : loc.getString('pricing_plans'),
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

            // Restore Purchases Button (Mobile only)
            if (!kIsWeb)
              Center(
                child: TextButton.icon(
                  onPressed: _isProcessing ? null : () => _restorePurchases(context, loc),
                  icon: const Icon(Icons.restore),
                  label: Text(
                    loc.currentLanguageCode == 'tr' 
                        ? 'Satın Alımları Geri Yükle' 
                        : 'Restore Purchases'
                  ),
                ),
              ),
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
              '${premiumService.remainingTrialDays} ${loc.getString("days") == "days" ? "gün" : loc.getString("days")} kaldı',
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
      {'icon': Icons.cloud, 'name': 'Unlimited Tests', 'tr': 'Sınırsız Test'},
      {'icon': Icons.backup, 'name': 'Cloud Backup', 'tr': 'Bulut Yedekleme'},
      {'icon': Icons.psychology, 'name': 'Advanced AI', 'tr': 'Gelişmiş AI'},
      {'icon': Icons.family_restroom, 'name': 'Unlimited Family', 'tr': 'Sınırsız Aile'},
      {'icon': Icons.restaurant_menu, 'name': 'Unlimited Diets', 'tr': 'Sınırsız Diyet'},
      {'icon': Icons.analytics, 'name': 'Advanced Analytics', 'tr': 'Gelişmiş Analitik'},
      {'icon': Icons.medical_services, 'name': 'Expert Doctor Consultation', 'tr': 'Uzman Doktor Görüşü', 'highlight': true},
      {'icon': Icons.video_call, 'name': 'Video Consultation', 'tr': 'Video Konsültasyon', 'highlight': true},
      {'icon': Icons.rate_review, 'name': 'Second Opinion', 'tr': 'İkinci Görüş', 'highlight': true},
    ];

    return features.map((feature) {
      PremiumFeature matchedFeature = PremiumFeature.cloudBackup;
      try {
        final nameStr = feature['name'] as String?;
        if (nameStr != null) {
          final searchTerm = nameStr.toLowerCase().split(' ').first;
          matchedFeature = PremiumFeature.values.firstWhere((f) => 
            f.name.toLowerCase().contains(searchTerm));
        }
      } catch (_) {
        matchedFeature = PremiumFeature.cloudBackup;
      }
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
                loc.currentLanguageCode == 'tr' 
                    ? (feature['tr'] as String)
                    : (feature['name'] as String),
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
                  loc.currentLanguageCode == 'tr' ? 'YAKINDA' : 'SOON',
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
          title: loc.currentLanguageCode == 'tr' ? 'Aylık' : 'Monthly',
          price: _paymentService?.getProductPrice(isYearly: false, isLifetime: false, languageCode: loc.currentLanguageCode) ?? 
                 (loc.currentLanguageCode == 'tr' ? '₺49.99' : '\$4.99'),
          period: loc.currentLanguageCode == 'tr' ? '/ay' : '/month',
          isPopular: false,
          isDark: isDark,
          onTap: () => _handlePurchase(context, premiumService, loc, isYearly: false, isLifetime: false),
        ),
        const SizedBox(height: 12),
        // Yearly
        _buildPlanCard(
          title: loc.currentLanguageCode == 'tr' ? 'Yıllık' : 'Yearly',
          price: _paymentService?.getProductPrice(isYearly: true, isLifetime: false, languageCode: loc.currentLanguageCode) ?? 
                 (loc.currentLanguageCode == 'tr' ? '₺399.99' : '\$39.99'),
          period: loc.currentLanguageCode == 'tr' ? '/yıl' : '/year',
          isPopular: true,
          isDark: isDark,
          onTap: () => _handlePurchase(context, premiumService, loc, isYearly: true, isLifetime: false),
        ),
        const SizedBox(height: 12),
        // Lifetime
        _buildPlanCard(
          title: loc.currentLanguageCode == 'tr' ? 'Yaşam Boyu' : 'Lifetime',
          price: _paymentService?.getProductPrice(isYearly: false, isLifetime: true, languageCode: loc.currentLanguageCode) ?? 
                 (loc.currentLanguageCode == 'tr' ? '₺999.99' : '\$99.99'),
          period: loc.currentLanguageCode == 'tr' ? 'Tek Seferlik' : 'One-time',
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
                        child: const Text(
                          'POPÜLER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
        throw Exception('Payment service not initialized');
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
            content: Text(loc.currentLanguageCode == 'tr' 
                ? 'Premium aktifleştirildi!' 
                : 'Premium activated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (_paymentService != null && !_paymentService!.purchasePending) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.currentLanguageCode == 'tr'
                ? 'Ödeme başlatılamadı. Lütfen tekrar deneyin.'
                : 'Payment could not be initiated. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.currentLanguageCode == 'tr' ? 'Hata' : 'Error'}: $e'),
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
        throw Exception('Payment service not initialized');
      }
      
      final success = await _paymentService!.restorePurchases();
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (loc.currentLanguageCode == 'tr'
                  ? 'Satın alımlar geri yüklendi'
                  : 'Purchases restored')
              : (loc.currentLanguageCode == 'tr'
                  ? 'Geri yüklenecek satın alım bulunamadı'
                  : 'No purchases found to restore')),
          backgroundColor: success ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.currentLanguageCode == 'tr' ? 'Hata' : 'Error'}: $e'),
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
}

