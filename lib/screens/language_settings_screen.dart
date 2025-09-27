import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/theme_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, ThemeService>(
      builder: (context, localizationService, themeService, child) {
        final isDark = themeService.isDarkMode;
        final isRTL = localizationService.isRTL;
        
        return Directionality(
          textDirection: localizationService.textDirection,
          child: Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0D1117)
                : const Color(0xFFF6F8FA),
            appBar: AppBar(
              title: Text(
                localizationService.getString('language'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              backgroundColor: isDark
                  ? const Color(0xFF161B22)
                  : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0,
              leading: IconButton(
                icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark
                                  ? const Color(0xFF238636)
                                  : const Color(0xFF2E7D32),
                              isDark
                                  ? const Color(0xFF1F6A2E)
                                  : const Color(0xFF388E3C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                localizationService.currentLanguageFlag,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizationService.getString('language'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current: ${localizationService.currentLanguageName}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Language Selection
                      Text(
                        localizationService.getString('select_language'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Language Options
                      ...localizationService.supportedLocales.map((locale) {
                        final languageCode = locale.languageCode;
                        final languageName = localizationService.languageNames[languageCode] ?? '';
                        final languageFlag = localizationService.languageFlags[languageCode] ?? '';
                        final isSelected = localizationService.currentLanguageCode == languageCode;
                        
                        return _buildLanguageOption(
                          context: context,
                          isDark: isDark,
                          languageCode: languageCode,
                          languageName: languageName,
                          languageFlag: languageFlag,
                          isSelected: isSelected,
                          onTap: () => _changeLanguage(context, languageCode),
                        );
                      }),

                      const SizedBox(height: 32),

                      // Language Features Info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  localizationService.getString('info'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              isDark: isDark,
                              icon: Icons.translate,
                              title: 'Dynamic Text Translation',
                              subtitle: 'All interface elements adapt to selected language',
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              isDark: isDark,
                              icon: Icons.format_textdirection_l_to_r,
                              title: 'RTL Support',
                              subtitle: 'Right-to-left layout for Arabic language',
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              isDark: isDark,
                              icon: Icons.calendar_month,
                              title: 'Localized Formatting',
                              subtitle: 'Date, time and number formats match locale',
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              isDark: isDark,
                              icon: Icons.medical_information,
                              title: 'Medical Terminology',
                              subtitle: 'Hemogram parameters in native language',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required bool isDark,
    required String languageCode,
    required String languageName,
    required String languageFlag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF238636) : const Color(0xFF2E7D32))
            : (isDark ? const Color(0xFF21262D) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF238636) : const Color(0xFF2E7D32))
              : (isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: (isDark ? const Color(0xFF238636) : const Color(0xFF2E7D32)).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
          color: isSelected
            ? Colors.white.withValues(alpha: 0.2)
            : (isDark ? const Color(0xFF30363D) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      languageFlag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageCode.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white70
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF30363D)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    
    if (localizationService.currentLanguageCode != languageCode) {
      localizationService.changeLanguage(languageCode);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Language changed to ${localizationService.languageNames[languageCode]}',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}