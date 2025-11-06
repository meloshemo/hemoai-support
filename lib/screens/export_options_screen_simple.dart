import 'package:flutter/material.dart';
import '../utils/color_compat.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_drawer.dart';
import '../services/cloud_sync_service.dart';
import '../services/export_service.dart';
import '../services/audit_log_service.dart';
import '../services/analytics_service.dart';

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
        final canPop = Navigator.of(context).canPop();
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: Provider.of<LocalizationService>(context, listen: false).getString('back'),
                  )
                : null,
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
          drawer: canPop ? null : const AppDrawer(),
          body: Consumer<LocalizationService>(
            builder: (context, localization, child) => SingleChildScrollView(
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
                    onTap: () async {
                      AuditLogService().logAction('export_tap', data: {'format': 'pdf'});
                      final analytics = Provider.of<AnalyticsService>(context, listen: false);
                      analytics.trackEvent('export_pdf_tap');
                      final svc = ExportService();
                      final name = patientName ?? localization.getString('patient_name_default');
                      final values = hemogramValues ?? const <String, double>{};
                      final messenger = ScaffoldMessenger.of(context);
                      final loc = localization;
                      if (values.isEmpty) {
                        _showInfo(context, loc.getString('no_data_available'));
                        return;
                      }
                      try {
                        final ok = await svc.exportHemogramToPdf(
                          hemogramValues: values,
                          patientName: name,
                          testDate: LocalizationService().formatDate(DateTime.now()),
                        );
                        analytics.trackEvent(ok ? 'export_pdf_success' : 'export_pdf_failed');
                        if (!context.mounted) return;
                        if (ok) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(loc.getString('export_success')),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _showErrorDialog(context, loc, 'PDF', loc.getString('export_failed'));
                        }
                      } catch (e) {
                        analytics.trackEvent('export_pdf_exception', parameters: {'error': e.toString()});
                        if (!context.mounted) return;
                        _showErrorDialog(context, loc, 'PDF', '${loc.getString('export_failed')}\n\n${loc.getString('error_details')}: $e');
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    icon: Icons.table_chart,
                    title: localization.getString('export_excel'),
                    subtitle: localization.getString('excel_description'),
                    onTap: () async {
                      AuditLogService().logAction('export_tap', data: {'format': 'excel'});
                      final analytics = Provider.of<AnalyticsService>(context, listen: false);
                      analytics.trackEvent('export_excel_tap');
                      final svc = ExportService();
                      final name = patientName ?? localization.getString('patient_name_default');
                      final values = hemogramValues ?? const <String, double>{};
                      final messenger = ScaffoldMessenger.of(context);
                      final loc = localization;
                      if (values.isEmpty) {
                        _showInfo(context, loc.getString('no_data_available'));
                        return;
                      }
                      try {
                        final ok = await svc.exportHemogramToExcel(
                          hemogramValues: values,
                          patientName: name,
                          testDate: LocalizationService().formatDate(DateTime.now()),
                        );
                        analytics.trackEvent(ok ? 'export_excel_success' : 'export_excel_failed');
                        if (!context.mounted) return;
                        if (ok) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(loc.getString('export_success')),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _showErrorDialog(context, loc, 'Excel', loc.getString('export_failed'));
                        }
                      } catch (e) {
                        analytics.trackEvent('export_excel_exception', parameters: {'error': e.toString()});
                        if (!context.mounted) return;
                        _showErrorDialog(context, loc, 'Excel', '${loc.getString('export_failed')}\n\n${loc.getString('error_details')}: $e');
                      }
                    },
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
                  const SizedBox(height: 16),
                  // Cloud backup (functional)
                  _buildExportButton(
                    context,
                    icon: Icons.cloud_upload,
                    title: localization.getString('cloud_backup_title'),
                    subtitle: localization.getString('cloud_backup_subtitle'),
                    onTap: () async {
                      final pwd = await _promptPassword(context, localization);
                      if (pwd == null || pwd.isEmpty) return;
                      final ok = await CloudSyncService().backupNow(pwd);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? localization.getString('cloud_backup_success') : localization.getString('cloud_backup_failed')),
                          backgroundColor: ok ? Colors.green : Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    icon: Icons.cloud_download,
                    title: localization.getString('cloud_restore_title'),
                    subtitle: localization.getString('cloud_restore_subtitle'),
                    onTap: () async {
                      final pwd = await _promptPassword(context, localization, isRestore: true);
                      if (pwd == null || pwd.isEmpty) return;
                      final ok = await CloudSyncService().restoreLatest(pwd, strategy: 'merge');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? localization.getString('cloud_restore_success') : localization.getString('cloud_restore_failed')),
                          backgroundColor: ok ? Colors.green : Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
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

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, LocalizationService loc, String format, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${loc.getString('export_failed')} ($format)'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('close')),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptPassword(BuildContext context, LocalizationService loc, {bool isRestore = false}) async {
    final controller = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRestore ? loc.getString('enter_backup_password') : loc.getString('set_backup_password')),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: loc.getString('password')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.getString('cancel'))),
          ElevatedButton(
            onPressed: () {
              result = controller.text.trim();
              Navigator.pop(context);
            },
            child: Text(loc.getString('ok')),
          ),
        ],
      ),
    );
    return result;
  }
}