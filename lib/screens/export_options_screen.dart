import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_drawer.dart';
import '../services/audit_log_service.dart';
import '../services/export_service.dart';
import '../services/backup_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
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
                    onTap: () async {
                      AuditLogService().logAction('export_tap', data: {'format': 'analysis'});
                      final analytics = Provider.of<AnalyticsService>(context, listen: false);
                      analytics.trackEvent('export_analysis_tap');
                      final svc = ExportService();
                      final name = patientName ?? localization.getString('patient_name_default');
                      final messenger = ScaffoldMessenger.of(context);
                      final successText = localization.getString('export_success');
                      final failedText = localization.getString('export_failed');
                      if ((analysisResult == null || analysisResult!.trim().isEmpty)) {
                        _showInfo(context, localization.getString('no_analysis_available'));
                        return;
                      }
                      try {
                        final ok = await svc.exportAnalysisReportToPdf(
                          hemogramValues: hemogramValues ?? const <String, double>{},
                          patientName: name,
                          analysisResult: analysisResult!,
                          recommendations: recommendations ?? const <String>[],
                          riskLevel: riskLevel ?? 'normal',
                        );
                        analytics.trackEvent(ok ? 'export_analysis_success' : 'export_analysis_failed');
                        if (!context.mounted) return;
                        if (ok) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(successText),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _showErrorDialog(context, localization, 'Analysis Report', failedText);
                        }
                      } catch (e) {
                        analytics.trackEvent('export_analysis_exception', parameters: {'error': e.toString()});
                        if (!context.mounted) return;
                        _showErrorDialog(context, localization, 'Analysis Report', '$failedText\n\n${localization.getString('error_details')}: $e');
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    icon: Icons.backup,
                    title: localization.getString('backup_data'),
                    subtitle: localization.getString('backup_data_desc'),
                    onTap: () async {
                      AuditLogService().logAction('backup_export');
                      final analytics = Provider.of<AnalyticsService>(context, listen: false);
                      analytics.trackEvent('backup_export_tap');
                      final backup = await BackupService().exportAll();
                      final name = 'hemoai_backup_${DateTime.now().millisecondsSinceEpoch}.json';
                      try {
                        // XFile.fromData expects Uint8List
                        final x = XFile.fromData(Uint8List.fromList(backup), name: name, mimeType: 'application/json');
                        await Share.shareXFiles([x], text: localization.getString('backup_ready'));
                        if (!context.mounted) return;
                        _showResult(context, localization, true);
                        analytics.trackEvent('backup_export_success', parameters: {'bytes': backup.length});
                      } catch (e) {
                        if (!context.mounted) return;
                        _showResult(context, localization, false);
                        analytics.trackEvent('backup_export_failed', parameters: {'error': e.toString()});
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    icon: Icons.restore,
                    title: localization.getString('restore_data'),
                    subtitle: localization.getString('restore_data_desc'),
                    onTap: () async {
                      AuditLogService().logAction('backup_restore_tap');
                      final analytics = Provider.of<AnalyticsService>(context, listen: false);
                      analytics.trackEvent('backup_restore_pick');
                      final loc = localization;
                      final messenger = ScaffoldMessenger.of(context);
                      final errorColor = Theme.of(context).colorScheme.error;
                      void showResult(bool ok) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? loc.getString('export_success') : loc.getString('export_failed'),
                            ),
                            backgroundColor: ok ? Colors.green : errorColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      void showInfo(String msg) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      try {
                        final res = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          withData: true,
                          type: FileType.custom,
                          allowedExtensions: const ['json'],
                        );
                        if (res == null || res.files.isEmpty || res.files.single.bytes == null) {
                          showInfo(loc.getString('no_file_selected'));
                          analytics.trackEvent('backup_restore_cancelled');
                          return;
                        }
                        final ok = await BackupService().restoreAll(res.files.single.bytes!.toList());
                        showResult(ok);
                        analytics.trackEvent(ok ? 'backup_restore_success' : 'backup_restore_failed');
                      } catch (e) {
                        showResult(false);
                        analytics.trackEvent('backup_restore_exception', parameters: {'error': e.toString()});
                      }
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
    return Semantics(
      button: true,
      label: '$title - $subtitle',
      child: Container(
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
                    semanticLabel: title,
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
      ),
    );
  }

  void _showResult(BuildContext context, LocalizationService localization, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? localization.getString('export_success') : localization.getString('export_failed'),
        ),
        backgroundColor: ok ? Colors.green : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, LocalizationService localization, String exportType, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(localization.getString('export_error_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getStringWithParams('export_error_message', {'type': exportType}),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.getString('troubleshooting_tips'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.getString('export_troubleshooting'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Try again - repeat the same export action
              Provider.of<AnalyticsService>(context, listen: false).trackEvent('export_retry_tap');
            },
            child: Text(localization.getString('try_again')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              localization.getString('close'),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}