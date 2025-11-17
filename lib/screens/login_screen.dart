import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'login_form_screen.dart';
import '../services/localization_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const bool _useModernHero = false; // reverted to classic card style
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1117)
          : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161B22)
            : const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'HEMOAI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Hero area (modern vs classic)
                _useModernHero
                    ? _buildModernHero(context)
                    : _buildClassicLogoCard(context),
                // Ana Butonlar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // Giriş Yap Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginFormScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E), // Kırmızı
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            LocalizationService.translate('login'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Üye Ol Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE53E3E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: Color(0xFFE53E3E), width: 2),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            LocalizationService.translate('register'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // E-posta ile Üye Ol Butonu (ikincil)
                      // Removed separate "Register with Email"; single Register handles phone or email inside
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _showAboutDialog(context),
                      child: Text(LocalizationService.translate('about')),
                    ),
                    TextButton(
                      onPressed: () => _showHelpDialog(context),
                      child:
                          Text(LocalizationService.translate('help_support')),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicLogoCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final outline = scheme.outlineVariant;
    return Container(
      margin: const EdgeInsets.only(bottom: 48),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outline.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/hemoai pic 1.O.jpg',
          width: 172,
          height: 172,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image load error: $error');
            debugPrint('Stack trace: $stackTrace');
            return Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE53E3E),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.local_hospital,
                size: 76,
                color: Color(0xFFE53E3E),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHero(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFE53E3E);
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      height: 280,
      margin: const EdgeInsets.only(bottom: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    accent.withValues(alpha: isDark ? 0.12 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Soft blobs
          Positioned(
            left: 24,
            top: 12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 48,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.05 : 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Glass card with gradient ring
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                    color:
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        accent,
                        Color(0xFFFF6B6B),
                        accent,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surface,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/hemoai pic 1.O.jpg',
                        width: 152,
                        height: 152,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image load error: $error');
                          debugPrint('Stack trace: $stackTrace');
                          return Container(
                            width: 152,
                            height: 152,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              size: 72,
                              color: accent,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // App name under the hero
          Positioned(
            bottom: 0,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  LocalizationService.translate('app_name'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LocalizationService>(
          builder: (context, localization, child) =>
              Text(localization.getString('about_hemoai')),
        ),
        content: Consumer<LocalizationService>(
          builder: (context, localization, child) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localization.getString('app_description'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${localization.getString('version')}: 1.0.0'),
                const SizedBox(height: 8),
                Text(
                    '${localization.getString('development_date')}: ${localization.getString('september_2025')}'),
                const SizedBox(height: 16),
                Text(
                  localization.getString('features'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                    '• ${localization.getString('ai_powered_hemogram_analysis')}'),
                Text(
                    '• ${localization.getString('personalized_diet_recommendations')}'),
                Text(
                    '• ${localization.getString('family_health_tracking_system')}'),
                Text(
                    '• ${localization.getString('alternative_medicine_guide')}'),
                Text('• ${localization.getString('smart_reminder_system')}'),
                const SizedBox(height: 16),
                Text(
                  localization.getString('app_disclaimer'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Consumer<LocalizationService>(
            builder: (context, localization, child) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localization.getString('close')),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, localizationService, child) => AlertDialog(
          title: Text(localizationService.getString('help_support')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizationService.getString('how_to_use'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(localizationService.getString('step_1_register')),
                Text(localizationService.getString('step_2_enter_values')),
                Text(localizationService.getString('step_3_view_analysis')),
                Text(localizationService.getString('step_4_diet_program')),
                Text(localizationService.getString('step_5_family_tracking')),
                const SizedBox(height: 16),
                Text(
                  localizationService.getString('important_reminders'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(localizationService.getString('not_medical_diagnosis')),
                Text(localizationService.getString('not_doctor_advice')),
                Text(localizationService.getString('emergency_see_doctor')),
                Text(localizationService.getString('regular_checkups')),
                const SizedBox(height: 16),
                Text(
                  localizationService.getString('for_support'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(localizationService.getString('send_feedback')),
                Text(localizationService.getString('report_issues')),
                Text(localizationService.getString('share_suggestions')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizationService.getString('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        localizationService.getString('feedback_received')),
                    backgroundColor: const Color(0xFFE53E3E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E)),
              child: Text(localizationService.getString('send_feedback_button'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
