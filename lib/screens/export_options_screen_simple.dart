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
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Consumer<LocalizationService>(
              builder: (context, localization, child) => Text(
                localization.getString('export_options'),
                style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
            foregroundColor: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
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
                    color: isDark ? theme.iconTheme.color?.withValues(alpha: 0.7) ?? scheme.onSurface.withValues(alpha: 0.7) : scheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localization.getString('export_options'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localization.getString('export_description'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) : const Color(0xFF656D76),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                  color: scheme.primary,
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
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) : const Color(0xFF656D76),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) : const Color(0xFF656D76),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}