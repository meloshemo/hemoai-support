// ignore_for_file: unused_field, unused_local_variable, unnecessary_to_list_in_spreads, avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
// foundation import not needed; keep material only
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../services/web_database_helper.dart';
import '../services/localization_service.dart';

class ExportOptionsScreen extends StatefulWidget {
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
  State<ExportOptionsScreen> createState() => _ExportOptionsScreenState();
}

class _ExportOptionsScreenState extends State<ExportOptionsScreen>
    with TickerProviderStateMixin {
  final ExportService _exportService = ExportService();
  late final WebDatabaseHelper _dbHelper;
  bool _isExporting = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Data from database
  Map<String, double>? _hemogramValues;
  String? _patientName;
  String? _analysisResult;
  List<String>? _recommendations;
  String? _riskLevel;
  List<Map<String, dynamic>>? _historicalData;

  @override
  void initState() {
    super.initState();
  _dbHelper = WebDatabaseHelper.instance;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId') ?? 1;
      
      // Get patient information
      final personalInfo = prefs.getString('personalInfo');
      if (personalInfo != null) {
        final infoMap = json.decode(personalInfo);
        _patientName = '${infoMap['firstName'] ?? ''} ${infoMap['lastName'] ?? ''}'.trim();
      } else {
        _patientName = LocalizationService().getString('patient');
      }

      // Get latest hemogram data
      try {
  final hemogramTests = await _dbHelper.getHemogramTests(userId);
        if (hemogramTests.isNotEmpty) {
          final latestTest = hemogramTests.first;
          _hemogramValues = Map<String, double>.from(latestTest['values'] ?? {});
          
          // Get historical data for trends
          _historicalData = hemogramTests;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LocalizationService.translate('error_loading_data')}: $e')),
          );
        }
      }
      // Perform analysis
      await _performAnalysis();
    } catch (e) {
  debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('error_loading_data')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performAnalysis() async {
    if (_hemogramValues == null || _hemogramValues!.isEmpty) return;

    try {
      // Basic analysis logic
      final wbc = _hemogramValues!['wbc'] ?? 0;
      final rbc = _hemogramValues!['rbc'] ?? 0;
      final hgb = _hemogramValues!['hgb'] ?? 0;
      final hct = _hemogramValues!['hct'] ?? 0;
      final plt = _hemogramValues!['plt'] ?? 0;

      // Simple risk assessment
      List<String> risks = [];
      List<String> recommendations = [];

      if (wbc < 4000 || wbc > 11000) {
        risks.add(LocalizationService.translate('abnormal_wbc'));
        recommendations.add(LocalizationService.translate('consult_doctor'));
      }
      if (hgb < 12 || hgb > 16) {
        risks.add(LocalizationService.translate('abnormal_hemoglobin'));
        recommendations.add(LocalizationService.translate('check_iron_levels'));
      }
      if (plt < 150000 || plt > 450000) {
        risks.add(LocalizationService.translate('abnormal_platelets'));
        recommendations.add(LocalizationService.translate('monitor_bleeding'));
      }

      _analysisResult = risks.isEmpty ? 
          LocalizationService.translate('normal_values') : 
          risks.join(', ');
      
      _riskLevel = risks.isEmpty ? 
          LocalizationService.translate('low_risk') : 
          LocalizationService.translate('moderate_risk');
      
      _recommendations = recommendations.isEmpty ? 
          [LocalizationService.translate('maintain_healthy_lifestyle')] : 
          recommendations;

    } catch (e) {
  debugPrint('Error performing analysis: $e');
      _analysisResult = LocalizationService.translate('analysis_error');
      _riskLevel = LocalizationService.translate('unknown_risk');
      _recommendations = [LocalizationService.translate('consult_healthcare_provider')];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;

        // Show loading screen while data is loading
        if (_isLoading) {
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
              backgroundColor: isDark
                  ? const Color(0xFF161B22)
                  : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocalizationService.translate('loading_data'),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
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
            backgroundColor: isDark
                ? const Color(0xFF161B22)
                : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: _showExportInfo,
              ),
            ],
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
                      padding: const EdgeInsets.all(20),
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
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.file_download,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocalizationService.translate('export_header_title'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService.translate('export_header_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Export Options
                    Text(
                      LocalizationService.translate('export_options'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hemogram Reports
                    _buildExportSection(
                      isDark: isDark,
                      title: LocalizationService.translate('hemogram_reports'),
                      subtitle: LocalizationService.translate('hemogram_reports_subtitle'),
                      icon: Icons.assignment,
                      iconColor: Colors.blue,
                      options: [
                        _ExportOption(
                          title: LocalizationService.translate('hemogram_pdf_report'),
                          description: LocalizationService.translate('hemogram_pdf_description'),
                          icon: Icons.picture_as_pdf,
                          onTap: _exportHemogramPdf,
                        ),
                        _ExportOption(
                          title: LocalizationService.translate('hemogram_excel_data'),
                          description: LocalizationService.translate('hemogram_excel_description'),
                          icon: Icons.table_chart,
                          onTap: _exportHemogramExcel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Analysis Reports
                    _buildExportSection(
                      isDark: isDark,
                      title: LocalizationService.translate('analysis_reports'),
                      subtitle: LocalizationService.translate('analysis_reports_subtitle'),
                      icon: Icons.analytics,
                      iconColor: Colors.purple,
                      options: [
                        _ExportOption(
                          title: LocalizationService.translate('analysis_report_pdf'),
                          description: LocalizationService.translate('analysis_report_pdf_description'),
                          icon: Icons.psychology,
                          onTap: _exportAnalysisReport,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reminders Export
                    _buildExportSection(
                      isDark: isDark,
                      title: LocalizationService.translate('reminders'),
                      subtitle: LocalizationService.translate('reminders_subtitle'),
                      icon: Icons.schedule,
                      iconColor: Colors.orange,
                      options: [
                        _ExportOption(
                          title: LocalizationService.translate('reminders_excel'),
                          description: LocalizationService.translate('reminders_excel_description'),
                          icon: Icons.event_note,
                          onTap: _exportReminders,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Comprehensive Report
                    _buildExportSection(
                      isDark: isDark,
                      title: LocalizationService.translate('comprehensive_report'),
                      subtitle: LocalizationService.translate('comprehensive_report_subtitle'),
                      icon: Icons.description,
                      iconColor: Colors.red,
                      options: [
                        _ExportOption(
                          title: LocalizationService.translate('comprehensive_health_report'),
                          description: LocalizationService.translate('comprehensive_health_report_description'),
                          icon: Icons.health_and_safety,
                          onTap: _exportComprehensiveReport,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportSection({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<_ExportOption> options,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Export Options
          ...options.map((option) => _buildExportOption(
            isDark: isDark,
            option: option,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required bool isDark,
    required _ExportOption option,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExporting ? null : option.onTap,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF30363D)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    option.icon,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isExporting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    Icons.download,
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Export Methods
  Future<void> _exportHemogramPdf() async {
    if (_hemogramValues == null || _hemogramValues!.isEmpty) {
      _showErrorMessage(LocalizationService.translate('no_hemogram_data'));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final success = await _exportService.exportHemogramToPdf(
        hemogramValues: _hemogramValues!,
        patientName: _patientName ?? LocalizationService.translate('patient'),
        testDate: DateTime.now().toString().split(' ')[0],
        doctorNotes: LocalizationService.translate('generated_by_hemoai'),
      );

      if (success) {
        _showSuccessMessage(LocalizationService.translate('pdf_export_success'));
      } else {
        _showErrorMessage(LocalizationService.translate('pdf_export_failed'));
      }
    } catch (e) {
      _showErrorMessage('${LocalizationService.translate('error')}: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportHemogramExcel() async {
    if (_hemogramValues == null || _hemogramValues!.isEmpty) {
      _showErrorMessage(LocalizationService.translate('no_hemogram_data'));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final success = await _exportService.exportHemogramToExcel(
        hemogramValues: _hemogramValues!,
        patientName: _patientName ?? LocalizationService.translate('patient'),
        testDate: DateTime.now().toString().split(' ')[0],
      );

      if (success) {
        _showSuccessMessage(LocalizationService.translate('excel_export_success'));
      } else {
        _showErrorMessage(LocalizationService.translate('excel_export_failed'));
      }
    } catch (e) {
      _showErrorMessage('${LocalizationService.translate('error')}: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAnalysisReport() async {
    if (widget.hemogramValues == null || widget.analysisResult == null) {
      _showErrorMessage(LocalizationService.translate('no_analysis_data'));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final success = await _exportService.exportAnalysisReportToPdf(
        hemogramValues: widget.hemogramValues!,
        patientName: widget.patientName ?? LocalizationService.translate('patient'),
        analysisResult: widget.analysisResult!,
        recommendations: widget.recommendations ?? [],
        riskLevel: widget.riskLevel ?? LocalizationService.translate('unknown_risk'),
      );

      if (success) {
        _showSuccessMessage(LocalizationService.translate('analysis_report_downloaded'));
      } else {
        _showErrorMessage(LocalizationService.translate('analysis_report_export_failed'));
      }
    } catch (e) {
      _showErrorMessage('${LocalizationService.translate('error_prefix')}$e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportReminders() async {
    setState(() => _isExporting = true);

    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final reminders = await notificationService.getAllNotifications();

      final success = await _exportService.exportRemindersToExcel(
        reminders: reminders,
        patientName: widget.patientName ?? LocalizationService.translate('patient'),
      );

      if (success) {
        _showSuccessMessage(LocalizationService.translate('reminders_export_success'));
      } else {
        _showErrorMessage(LocalizationService.translate('reminders_export_failed'));
      }
    } catch (e) {
      _showErrorMessage('${LocalizationService.translate('error_prefix')}$e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportComprehensiveReport() async {
    if (widget.hemogramValues == null) {
      _showErrorMessage(LocalizationService.translate('no_hemogram_data'));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final reminders = await notificationService.getAllNotifications();

      final success = await _exportService.exportComprehensiveReport(
        patientName: widget.patientName ?? LocalizationService.translate('patient'),
        latestHemogram: widget.hemogramValues!,
        historicalData: [], // TODO: Load from database
        reminders: reminders,
        analysisResult: widget.analysisResult ?? LocalizationService.translate('no_data_available'),
        recommendations: widget.recommendations ?? [],
      );

      if (success) {
        _showSuccessMessage(LocalizationService.translate('comprehensive_report_export_success'));
      } else {
        _showErrorMessage(LocalizationService.translate('comprehensive_report_export_failed'));
      }
    } catch (e) {
      _showErrorMessage('${LocalizationService.translate('error_prefix')}$e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showExportInfo() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          final isDark = themeService.isDarkMode;
          
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF21262D) : Colors.white,
            title: Text(
              LocalizationService.translate('export_info_title'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.translate('export_info_content'),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  LocalizationService.translate('ok'),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ExportOption {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ExportOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}