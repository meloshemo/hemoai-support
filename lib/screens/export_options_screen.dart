import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_drawer.dart';

class ExportOptionsScreen extends StatelessWidget {
  final String? patientName;
  final Map<String, double>? hemogramValues;
  final String? analysisResult;
  final List<String>? recommendations;
  final String? riskLevel;

  const ExportOptionsScreen({
    super.key,
    this.patientName,
    this.hemogramValues,
    this.analysisResult,
    this.recommendations,
    this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF6F8FA),
          appBar: AppBar(
            title: Consumer<LocalizationService>(
              builder: (context, localization, child) => Text(
                localization.getString('export_options'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
            foregroundColor: isDark ? Colors.white : const Color(0xFF24292F),
            elevation: 0,
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: Consumer<LocalizationService>(
            builder: (context, localization, child) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.download,
                    size: 80,
                    color: isDark ? Colors.white70 : const Color(0xFFE53E3E),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localization.getString('export_options'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF24292F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localization.getString('export_description'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF656D76),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _buildExportButton(
                    context,
                    icon: Icons.picture_as_pdf,
                    title: localization.getString('export_pdf'),
                    subtitle: localization.getString('pdf_description'),
                    onTap: () => _showComingSoon(context, localization),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    icon: Icons.table_chart,
                    title: localization.getString('export_excel'),
                    subtitle: localization.getString('excel_description'),
                    onTap: () => _showComingSoon(context, localization),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    icon: Icons.analytics,
                    title: localization.getString('export_analysis'),
                    subtitle: localization.getString('analysis_description'),
                    onTap: () => _showComingSoon(context, localization),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: const Color(0xFFE53E3E),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF24292F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF656D76),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.white54 : const Color(0xFF656D76),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, LocalizationService localization) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localization.getString('coming_soon'),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}