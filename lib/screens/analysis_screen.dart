import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/color_compat.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../services/audit_log_service.dart';
import '../services/preferences_service.dart';
import '../services/export_service.dart';
import '../services/localization_service.dart';
import '../services/analysis_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';
import 'export_options_screen_simple.dart' as export_options;

class AnalysisScreen extends StatefulWidget {
  final Map<String, double> hemogramValues;

  const AnalysisScreen({
    Key? key,
    required this.hemogramValues,
  }) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  final PreferencesService _prefsService = PreferencesService();
  final ExportService _exportService = ExportService();
  final AnalysisService _analysisService = AnalysisService();
  
  Map<String, double> currentValues = {};
  List<Map<String, dynamic>> testHistory = [];
  bool _isExporting = false;
  AnalysisResult? _result;
  bool _loadingAnalysis = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Reference ranges keyed by canonical parameter codes
  final Map<String, Map<String, double>> referenceRanges = {
    'hemoglobin': {'min': 12.0, 'max': 17.0},
    'glucose': {'min': 70.0, 'max': 100.0},
    'calcium': {'min': 8.6, 'max': 10.2},
    'sodium': {'min': 135.0, 'max': 145.0},
    'potassium': {'min': 3.5, 'max': 5.1},
    'chloride': {'min': 98.0, 'max': 107.0},
    'alt': {'min': 7.0, 'max': 56.0},
    'ast': {'min': 10.0, 'max': 40.0},
    'ggt': {'min': 9.0, 'max': 48.0},
    'total_bilirubin': {'min': 0.1, 'max': 1.2},
    'direct_bilirubin': {'min': 0.0, 'max': 0.3},
    'crp': {'min': 0.0, 'max': 5.0},
    'iron': {'min': 60.0, 'max': 170.0},
    'uibc': {'min': 110.0, 'max': 370.0},
    'tibc': {'min': 240.0, 'max': 450.0},
    'tsh': {'min': 0.4, 'max': 4.0},
    'free_t3': {'min': 2.0, 'max': 4.4},
    'free_t4': {'min': 0.8, 'max': 1.8},
    'vitamin_d3': {'min': 20.0, 'max': 50.0},
    'vitamin_b12': {'min': 200.0, 'max': 900.0},
  };

  @override
  void initState() {
    super.initState();
    currentValues = Map.from(widget.hemogramValues);
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadTestHistory();
    _runAnalysis();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Background audit: analysis viewed
    try {
      AuditLogService().logAction('analysis_viewed', data: {
        'params_count': currentValues.length,
      });
    } catch (e) {
      debugPrint('Audit log error: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadTestHistory() async {
    try {
      final userId = _prefsService.getCurrentUserId();
      if (userId != null) {
        final db = DatabaseHelper.instance;
        final rows = await db.getHemogramTests(userId);
        if (mounted) {
          setState(() {
            testHistory = rows;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading test history: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load test history: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _runAnalysis() async {
    if (currentValues.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No values to analyze';
          _loadingAnalysis = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _loadingAnalysis = true;
          _errorMessage = null;
        });
      }
      
      final uid = _prefsService.getCurrentUserId() ?? 0;
      final res = await _analysisService.analyze(
        userId: uid,
        currentValues: currentValues,
      );
      
      if (mounted) {
        setState(() {
          _result = res;
          _errorMessage = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Analysis error: $e\n$stackTrace');
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        setState(() {
          _errorMessage = '${loc.getString('error_prefix')} ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAnalysis = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
      drawer: const AppDrawer(currentRoute: '/analysis'),
      appBar: UnifiedAppBar(
        title: localizationService.getString('analysis_results'),
        currentRoute: '/analysis',
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: localizationService.getString('import'),
            onPressed: () => Navigator.of(context).pushNamed('/data_import'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              _loadTestHistory();
              _runAnalysis();
            },
          ),
        ],
      ),
      body: _loadingAnalysis
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizationService.getString('analyzing') ?? 'Analyzing...',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null && _result == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _runAnalysis,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
            // Main Analysis Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53E3E).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        localizationService.getString('hemogram_analysis'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _result?.summary ?? _getOverallAssessment(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final rl = _mapRiskToLocalized(_result?.riskLabel) ?? _getRiskLevel();
                    Color c = Colors.green;
                    if (rl == Provider.of<LocalizationService>(context, listen: false).getString('risk_level_medium')) {
                      c = Colors.orange;
                    } else if (rl == Provider.of<LocalizationService>(context, listen: false).getString('risk_level_high')) {
                      c = Colors.red;
                    } else if (rl == Provider.of<LocalizationService>(context, listen: false).getString('risk_level_very_high')) {
                      c = Colors.red.shade900;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.withOpacity(0.9), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, color: c, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            rl,
                            style: TextStyle(color: c, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // AI Insights Card with Chart
            _buildAIInsightsCard(),
            
            const SizedBox(height: 24),

            // Smart Summary Card
            _buildSmartSummaryCard(),
            
            const SizedBox(height: 24),

            // Trend Analysis
            if (_result != null && _result!.trends.isNotEmpty) _buildTrendsCard(),
            
            const SizedBox(height: 24),
            
            // Health Score Visualization
            _buildHealthScoreVisualization(),
            
            const SizedBox(height: 24),
            
            // Hemogram Values List (popular markers, locale-ordered)
            _buildParametersList(localizationService),
            
            const SizedBox(height: 24),
            
            // Overall Evaluation
            _buildOverallEvaluation(localizationService),
            
            const SizedBox(height: 24),
            
            // Recommendations
            _buildRecommendations(localizationService),
            
            const SizedBox(height: 24),
            
            // Test History
            if (testHistory.isNotEmpty) _buildTestHistory(localizationService),
            
            const SizedBox(height: 24),
            
            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: Text(localizationService.getString('detailed_recommendations')),
                    onPressed: () {
                      _showDetailedAdvice(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: Text(localizationService.getString('share_report_button')),
                    onPressed: () {
                      _shareReport(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Professional Export Options
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF238636)
                        : const Color(0xFF2E7D32),
                    Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF1F6A2E)
                        : const Color(0xFF388E3C),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_download, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        localizationService.getString('export_options_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizationService.getString('export_options_subtitle'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToExportOptions(context),
                      icon: const Icon(Icons.launch, size: 20),
                      label: Text(
                        localizationService.getString('export_options_go'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: Text(localizationService.getString('quick_pdf')),
                          onPressed: () => _quickExportPDF(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: Text(localizationService.getString('quick_excel')),
                          onPressed: () => _quickExportExcel(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
                    ),
                  ),
                ),
              );
  }

  Widget _buildSmartSummaryCard() {
    final loc = Provider.of<LocalizationService>(context);
    final score = _result?.riskScore ?? _computeRiskScore();
    final flags = _result?.flags
            .take(3)
            .map((f) => {
                  'key': f.key,
                  'direction': f.direction,
                  'severity': f.severity,
                })
            .toList() ??
        _getTopFlags(3);
    // color scale: 0-33 green, 34-66 orange, 67-100 red
    Color scoreColor;
    if (score <= 33) {
      scoreColor = Colors.green;
    } else if (score <= 66) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(
                  loc.getString('smart_summary_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${loc.getString('risk_score_label')}: ${score.toStringAsFixed(0)}',
                        style: TextStyle(color: scoreColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Flags
            Text(
              loc.getString('top_flags_label'),
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            if (flags.isEmpty)
              Text(
                loc.getString('all_values_normal_message'),
                style: TextStyle(color: Colors.grey[700]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: flags.map((f) {
                  final label = _localizedParamName(f['key'] as String);
                  final dir = f['direction'] as String; // 'low'|'high'|'very_high'
                  Color c = dir == 'low' ? Colors.orange : (dir == 'high' ? Colors.red : Colors.red.shade900);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(dir == 'low' ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: c),
                        const SizedBox(width: 6),
                        Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            // Next steps
            Text(
              loc.getString('next_steps_label'),
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final abnormalCount = _countAbnormal();
              final hasVeryHigh = _hasVeryHigh();
              final items = <String>[];
              if (abnormalCount == 0) {
                items.add(loc.getString('maintain_healthy_habits'));
              } else {
                if (hasVeryHigh || abnormalCount >= 3) {
                  items.add(loc.getString('multiple_abnormalities'));
                }
                items.add(loc.getString('consider_follow_up'));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 16, color: Color(0xFFE53E3E)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _computeRiskScore() {
    // Weighted simple scorer: each abnormal adds 15, very high adds +20 bonus, capped at 100
    int abnormal = 0;
    int bonus = 0;
    currentValues.forEach((key, value) {
      final range = referenceRanges[key];
      if (range == null) return;
      if (value < range['min']! || value > range['max']!) {
        abnormal += 1;
        if (value > range['max']!) {
          final max = range['max']!;
          if (value > max * 1.5) bonus += 20;
        }
      }
    });
    double score = abnormal * 15 + bonus.toDouble();
    if (score > 100) score = 100;
    return score;
  }

  List<Map<String, dynamic>> _getTopFlags(int count) {
    final List<Map<String, dynamic>> flags = [];
    currentValues.forEach((key, value) {
      final range = referenceRanges[key];
      if (range == null) return;
      if (value < range['min']!) {
        final diff = (range['min']! - value) / range['min']!;
        flags.add({'key': key, 'severity': diff, 'direction': 'low'});
      } else if (value > range['max']!) {
        final diff = (value - range['max']!) / range['max']!;
        final isVery = value > range['max']! * 1.5;
        flags.add({'key': key, 'severity': isVery ? diff + 0.5 : diff, 'direction': isVery ? 'very_high' : 'high'});
      }
    });
    flags.sort((a, b) => (b['severity'] as num).compareTo(a['severity'] as num));
    return flags.take(count).toList();
  }

  int _countAbnormal() {
    int abnormal = 0;
    currentValues.forEach((key, value) {
      final range = referenceRanges[key];
      if (range == null) return;
      if (value < range['min']! || value > range['max']!) {
        abnormal += 1;
      }
    });
    return abnormal;
  }

  bool _hasVeryHigh() {
    bool veryHigh = false;
    currentValues.forEach((key, value) {
      final range = referenceRanges[key];
      if (range == null) return;
      if (value > range['max']!) {
        final max = range['max']!;
        if (value > max * 1.5) veryHigh = true;
      }
    });
    return veryHigh;
  }

  List<String> _orderedMarkerKeys(LocalizationService loc) {
    // Default order as provided (popular set)
    final def = [
      'hemoglobin',
      'glucose',
      'calcium',
      'sodium',
      'potassium',
      'chloride',
      'alt',
      'ast',
      'ggt',
      'total_bilirubin',
      'direct_bilirubin',
      'crp',
      'iron',
      'uibc',
      'tibc',
      'tsh',
      'free_t3',
      'free_t4',
      'vitamin_d3',
      'vitamin_b12',
    ];
    final lang = loc.currentLanguageCode;
    // Locale-specific tweaks (can be expanded later)
    if (lang == 'tr') {
      return def; // matches requested order
    } else if (lang == 'en') {
      // Slightly adjust to reflect common panel grouping
      return [
        'glucose', 'sodium', 'potassium', 'chloride', 'calcium',
        'alt', 'ast', 'ggt', 'total_bilirubin', 'direct_bilirubin', 'crp',
        'hemoglobin', 'iron', 'uibc', 'tibc',
        'tsh', 'free_t3', 'free_t4', 'vitamin_d3', 'vitamin_b12',
      ];
    }
    return def;
  }

  Widget _buildParametersList(LocalizationService localizationService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(
                  localizationService.getString('hemogram_values'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._orderedMarkerKeys(localizationService)
                .where((k) => currentValues.containsKey(k))
                .map((k) => _buildParameterRow(k, currentValues[k]!))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String parameter, double value) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final range = _result?.referenceRanges[parameter] ?? referenceRanges[parameter];
    Color statusColor = Colors.green;
    String statusKey = 'status_normal';

    if (range != null) {
      if (value < range['min']!) {
        statusColor = Colors.orange;
        statusKey = 'status_low';
      } else if (value > range['max']!) {
        // Detect extremely high values as "very high" (e.g., > 1.5x upper bound)
        final max = range['max']!;
        if (value > max * 1.5) {
          statusColor = Colors.red.shade900;
          statusKey = 'status_very_high';
        } else {
          statusColor = Colors.red;
          statusKey = 'status_high';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(width: 4, color: statusColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedParamName(parameter),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (range != null)
                  Text(
                    loc.getStringWithParams('normal_range_template', {
                      'min': range['min']!.toStringAsFixed(1),
                      'max': range['max']!.toStringAsFixed(1),
                    }),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                loc.getString(statusKey),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallEvaluation(LocalizationService localizationService) {
    List<String> abnormalValues = [];
    List<String> normalValues = [];
    
    currentValues.forEach((parameter, value) {
      final range = referenceRanges[parameter];
      if (range != null) {
        if (value < range['min']! || value > range['max']!) {
          abnormalValues.add(parameter);
        } else {
          normalValues.add(parameter);
        }
      }
    });

    Color cardColor = abnormalValues.isEmpty ? Colors.green : Colors.orange;
    IconData cardIcon = abnormalValues.isEmpty ? Icons.check_circle : Icons.warning;
    String title = abnormalValues.isEmpty ? localizationService.getString('general_status_good') : localizationService.getString('attention_required');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(cardIcon, color: cardColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (abnormalValues.isNotEmpty) ...[
              Text(
                localizationService.getString('abnormal_values_heading'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...abnormalValues.map((param) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• ' + _localizedParamName(param), style: TextStyle(color: Colors.grey[700])),
              )).toList(),
            ] else ...[
              Text(
                localizationService.getString('all_values_normal_message'),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(LocalizationService localizationService) {
    List<String> recommendations = _result?.recommendations ?? _generateRecommendations();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(
                  localizationService.getString('recommendations'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                ...recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Color(0xFFE53E3E), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final items = _result!.trends
        .toList()
        ..sort((a, b) => b.percentChange.abs().compareTo(a.percentChange.abs()));
    final top = items.take(5).toList();
    String dirLabel(TrendDirection d) {
      switch (d) {
        case TrendDirection.up:
          return loc.getString('trend_up');
        case TrendDirection.down:
          return loc.getString('trend_down');
        case TrendDirection.stable:
          return loc.getString('trend_stable');
      }
    }
    Color dirColor(TrendDirection d) {
      switch (d) {
        case TrendDirection.up:
          return Colors.orange;
        case TrendDirection.down:
          return Colors.green;
        case TrendDirection.stable:
          return Colors.blueGrey;
      }
    }
    IconData dirIcon(TrendDirection d) {
      switch (d) {
        case TrendDirection.up:
          return Icons.trending_up;
        case TrendDirection.down:
          return Icons.trending_down;
        case TrendDirection.stable:
          return Icons.trending_flat;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(
                  loc.getString('trend_last_6_months'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...top.map((t) {
              final label = _localizedParamName(t.key);
              final dir = dirLabel(t.direction);
              final pct = t.percentChange.toStringAsFixed(1);
              final chipColor = dirColor(t.direction);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(width: 4, color: chipColor)),
                ),
                child: Row(
                  children: [
                    Icon(dirIcon(t.direction), color: chipColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.getStringWithParams('trend_change_template', {
                          'param': label,
                          'direction': dir,
                          'percent': pct,
                        }),
                        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${t.sampleCount}x', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Normalize string by converting to lowercase and stripping common Turkish diacritics
  String _normalizeAscii(String input) {
  final lower = input.toLowerCase();
  return lower
    .replaceAll('\u00E7', 'c') // ç
    .replaceAll('\u011F', 'g') // ğ
    .replaceAll('\u0131', 'i') // ı
    .replaceAll('\u00F6', 'o') // ö
    .replaceAll('\u015F', 's') // ş
    .replaceAll('\u00FC', 'u'); // ü
  }

  String _localizedParamName(String raw) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // If already canonical key, translate directly
    const canonicalKeys = {
      'hemoglobin','glucose','calcium','sodium','potassium','chloride','alt','ast','ggt','total_bilirubin','direct_bilirubin','crp','iron','uibc','tibc','tsh','free_t3','free_t4','vitamin_d3','vitamin_b12',
    };
    if (canonicalKeys.contains(raw)) return loc.getString(raw);

    final lower = _normalizeAscii(raw);
    if (lower.contains('glucose') || lower.contains('glikoz')) return loc.getString('glucose');
    if (lower.contains('calcium') || lower.contains('kalsiyum')) return loc.getString('calcium');
    if (lower.contains('sodium') || lower.contains('sodyum')) return loc.getString('sodium');
    if (lower.contains('potassium') || lower.contains('potasyum')) return loc.getString('potassium');
    if (lower.contains('chloride') || lower.contains('klor') || lower.contains('chlor')) return loc.getString('chloride');
    if (lower.contains('bilirubin') && lower.contains('total')) return loc.getString('total_bilirubin');
    if (lower.contains('bilirubin') && (lower.contains('direct') || lower.contains('direkt'))) return loc.getString('direct_bilirubin');
    if (lower.contains('tsh')) return loc.getString('tsh');
    if (lower.contains('free t3') || lower.contains('ft3')) return loc.getString('free_t3');
    if (lower.contains('free t4') || lower.contains('ft4')) return loc.getString('free_t4');
    if (lower.contains('vitamin d')) return loc.getString('vitamin_d3');
    if (lower.contains('b12')) return loc.getString('vitamin_b12');
    if (lower.contains('uibc')) return loc.getString('uibc');
    if (lower.contains('tibc')) return loc.getString('tibc');
    if (lower.contains('crp')) return loc.getString('crp');
    if (lower.contains('alt')) return loc.getString('alt');
    if (lower.contains('ast')) return loc.getString('ast');
    if (lower.contains('ggt')) return loc.getString('ggt');
    if (lower.contains('hemoglobin')) return loc.getString('hemoglobin');
    if (lower.contains('demir') || lower.contains('iron')) return loc.getString('iron');
    return raw;
  }

  Widget _buildTestHistory(LocalizationService localizationService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(
                  localizationService.getString('test_history'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (testHistory.isNotEmpty) ...[
              Text(
                localizationService.getStringWithParams(
                  'test_history_count',
                  {'count': testHistory.length.toString()},
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ...testHistory.map((test) => _buildHistoryItem(test)).toList(),
            ] else ...[
              Text(
                localizationService.getString('first_test_message'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> test) {
    final rawDate = test['test_date'] as String? ?? DateTime.now().toIso8601String();
    DateTime testDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    String riskLevel = (test['risk_level'] ?? 'low').toString();
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // Normalize any stored label/code and derive color + localized label
    final rl = _normalizeAscii(riskLevel);
    Color riskColor;
    if (rl == 'yuksek' || rl == 'high') {
      riskColor = Colors.red;
    } else if (rl == 'orta' || rl == 'medium') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }
    String riskLabel;
    if (rl == 'yuksek' || rl == 'high') {
      riskLabel = loc.getString('risk_level_high');
    } else if (rl == 'orta' || rl == 'medium') {
      riskLabel = loc.getString('risk_level_medium');
    } else {
      riskLabel = loc.getString('risk_level_low');
    }

    // Build expandable item showing full parameters for that test
    final paramWidgets = <Widget>[];
    final keys = [
      'hemoglobin','iron','leukocyte','erythrocyte','hematocrit','platelet','mcv','mch','mchc','rdw','neutrophil','lymphocyte','monocyte','eosinophil','basophil'
    ];
    for (final k in keys) {
      final v = test[k];
      if (v != null) {
        final displayKey = _mapDbKeyToCanonical(k);
        paramWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _localizedParamName(displayKey),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Text((v as num).toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(width: 3, color: riskColor)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '${testDate.day}/${testDate.month}/${testDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: paramWidgets),
          ],
        ),
      ),
    );
  }

  String _mapDbKeyToCanonical(String dbKey) {
    switch (dbKey) {
      case 'leukocyte':
        return 'white_blood_cells';
      case 'erythrocyte':
        return 'red_blood_cells';
      case 'platelet':
        return 'platelets';
      default:
        return dbKey;
    }
  }

  String _getOverallAssessment() {
    List<String> abnormalValues = [];
    
    currentValues.forEach((parameter, value) {
      final range = referenceRanges[parameter];
      if (range != null) {
        if (value < range['min']! || value > range['max']!) {
          abnormalValues.add(parameter);
        }
      }
    });

    final loc = Provider.of<LocalizationService>(context, listen: false);
    if (abnormalValues.isEmpty) {
      return loc.getString('overall_assessment_normal');
    } else if (abnormalValues.length <= 2) {
      return loc.getString('overall_assessment_some_abnormal');
    } else {
      return loc.getString('overall_assessment_many_abnormal');
    }
  }

  List<String> _generateRecommendations() {
    List<String> recommendations = [];
    
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // Hemoglobin low
    final hb = currentValues['hemoglobin'];
    if (hb != null && hb < 12.0) {
      recommendations.add(loc.getString('hemoglobin_low_recommendation'));
    }
    // Iron low
    final iron = currentValues['iron'];
    if (iron != null && iron < 60.0) {
      recommendations.add(loc.getString('iron_low_recommendation'));
    }
    // Glucose high (fasting)
    final glucose = currentValues['glucose'];
    if (glucose != null && glucose > 100.0) {
      recommendations.add(loc.getString('glucose_high_recommendation'));
    }
    // Vitamin D3 low
    final vD = currentValues['vitamin_d3'];
    if (vD != null && vD < 20.0) {
      recommendations.add(loc.getString('vitamin_d3_low_recommendation'));
    }
    // TSH abnormal
    final tsh = currentValues['tsh'];
    if (tsh != null && (tsh < 0.4 || tsh > 4.0)) {
      recommendations.add(loc.getString('tsh_abnormal_recommendation'));
    }
    
  // General recommendations
    if (recommendations.isEmpty) {
      recommendations.addAll([
        loc.getString('recommendation_default_1'),
        loc.getString('recommendation_default_2'),
        loc.getString('recommendation_default_3'),
      ]);
    } else {
      recommendations.add(Provider.of<LocalizationService>(context, listen: false).getString('recommendation_follow_up_doctor'));
    }
    
    return recommendations;
  }

  void _showDetailedAdvice(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Provider.of<LocalizationService>(context, listen: false).getString('detailed_health_advice_title')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('general_health_tips_heading'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('tip_water_intake')),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('tip_exercise')),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('tip_balanced_diet')),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('tip_sleep')),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('tip_stress_management')),
                const SizedBox(height: 12),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('checks_heading'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('check_semiannual_hemogram')),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('check_annual_general')),
                Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('check_follow_abnormal')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('ok')),
            ),
          ],
        );
      },
    );
  }

  void _shareReport(BuildContext context) {
    String report = _generateTextReport();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Provider.of<LocalizationService>(context, listen: false).getString('report_share_dialog_title')),
          content: SingleChildScrollView(
            child: Text(report),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                // Sharing functionality would be implemented here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getString('report_copied'))),
                );
              },
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('copy')),
            ),
          ],
        );
      },
    );
  }

  String _generateTextReport() {
  final loc = Provider.of<LocalizationService>(context, listen: false);
  StringBuffer report = StringBuffer();
  report.writeln(loc.getString('report_header'));
  report.writeln('${loc.getString('date_label')}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    report.writeln('');
  report.writeln(loc.getString('report_section_values'));
    report.writeln('==================');
    
    currentValues.forEach((parameter, value) {
      final range = referenceRanges[parameter];
      String status = 'status_normal';
      if (range != null) {
        if (value < range['min']!) status = 'status_low';
        if (value > range['max']!) {
          final max = range['max']!;
          status = (value > max * 1.5) ? 'status_very_high' : 'status_high';
        }
      }
      report.writeln('${_localizedParamName(parameter)}: ${value.toStringAsFixed(1)} [${loc.getString(status)}]');
    });
    
    report.writeln('');
  report.writeln(loc.getString('report_section_evaluation'));
    report.writeln(_getOverallAssessment());
    
    return report.toString();
  }

  // ===== REPORT AND EXPORT FEATURES =====

  // Navigate to Export Options Screen
  void _navigateToExportOptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => export_options.ExportOptionsScreen(
          patientName: Provider.of<LocalizationService>(context, listen: false).getString('patient_placeholder'), // TODO: Get from user profile
          hemogramValues: currentValues,
          analysisResult: _getOverallAssessment(),
          recommendations: _generateRecommendations(),
          riskLevel: _getRiskLevel(),
        ),
      ),
    );
  }

  // Quick Export PDF
  Future<void> _quickExportPDF(BuildContext context) async {
    if (currentValues.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      final success = await _exportService.exportHemogramToPdf(
        hemogramValues: currentValues,
  patientName: Provider.of<LocalizationService>(context, listen: false).getString('patient_placeholder'),
  testDate: DateTime.now().toString().split(' ')[0],
  doctorNotes: Provider.of<LocalizationService>(context, listen: false).getString('doctor_notes_generated_by_hemoai'),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(Provider.of<LocalizationService>(context, listen: false).getString('pdf_download_success')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('PDF export failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<LocalizationService>(context, listen: false).getString('pdf_export_error_prefix') + e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // Quick Export Excel
  Future<void> _quickExportExcel(BuildContext context) async {
    if (currentValues.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      final success = await _exportService.exportHemogramToExcel(
        hemogramValues: currentValues,
  patientName: Provider.of<LocalizationService>(context, listen: false).getString('patient_placeholder'),
        testDate: DateTime.now().toString().split(' ')[0],
        historicalData: testHistory,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_download_success')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Excel export failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_export_error_prefix') + e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _getRiskLevel() {
    List<String> abnormalValues = [];
    bool hasVeryHigh = false;
    
    currentValues.forEach((parameter, value) {
      final range = referenceRanges[parameter];
      if (range != null) {
        if (value < range['min']! || value > range['max']!) {
          abnormalValues.add(parameter);
          if (value > range['max']!) {
            final max = range['max']!;
            if (value > max * 1.5) hasVeryHigh = true;
          }
        }
      }
    });

    if (abnormalValues.isEmpty) {
      return Provider.of<LocalizationService>(context, listen: false).getString('risk_level_low');
    } else if (hasVeryHigh) {
      return Provider.of<LocalizationService>(context, listen: false).getString('risk_level_very_high');
    } else if (abnormalValues.length <= 2) {
      return Provider.of<LocalizationService>(context, listen: false).getString('risk_level_medium');
    } else {
      return Provider.of<LocalizationService>(context, listen: false).getString('risk_level_high');
    }
  }

  String? _mapRiskToLocalized(String? risk) {
    if (risk == null) return null;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    switch (risk) {
      case 'low':
        return loc.getString('risk_level_low');
      case 'medium':
        return loc.getString('risk_level_medium');
      case 'high':
        return loc.getString('risk_level_high');
      case 'very_high':
        return loc.getString('risk_level_very_high');
      default:
        return null;
    }
  }

  Widget _buildAIInsightsCard() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
  // Get top 3 abnormal parameters for visualization, normalized to Map shape
  final List<Map<String, dynamic>> topParams = _result != null
    ? _result!.flags
      .take(3)
      .map((f) => {
          'key': f.key,
          'direction': f.direction,
          'severity': f.severity,
        })
      .toList()
    : _getTopFlags(3);
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1F2E), const Color(0xFF0F1419)]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology, color: Color(0xFFE53E3E), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Powered by advanced analysis',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Mini chart for top parameters
            if (topParams.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= topParams.length) return const Text('');
                            final param = topParams[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _localizedParamName(param['key'] as String).substring(0, _localizedParamName(param['key'] as String).length > 4 ? 4 : _localizedParamName(param['key'] as String).length),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: topParams.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final param = entry.value;
                      final severity = (param['severity'] as num).toDouble() * 100;
                      final isHigh = (param['direction'] as String).contains('high');
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: severity.clamp(0, 100),
                            color: isHigh ? Colors.red : Colors.orange,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Key insights
            ..._buildKeyInsights(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildKeyInsights() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insights = <Widget>[];
    
    final abnormalCount = _countAbnormal();
    final hasVeryHigh = _hasVeryHigh();
    
    if (abnormalCount == 0) {
      insights.add(_insightItem(
        icon: Icons.check_circle,
        color: Colors.green,
        text: loc.getString('all_values_normal_message'),
        isDark: isDark,
      ));
    } else {
      if (hasVeryHigh) {
        insights.add(_insightItem(
          icon: Icons.warning,
          color: Colors.red,
          text: 'Critical values detected - immediate attention recommended',
          isDark: isDark,
        ));
      }
      if (abnormalCount >= 3) {
        insights.add(_insightItem(
          icon: Icons.insights,
          color: Colors.orange,
          text: 'Multiple parameters require monitoring',
          isDark: isDark,
        ));
      }
      insights.add(_insightItem(
        icon: Icons.trending_up,
        color: Colors.blue,
        text: 'Consider follow-up testing in 3-6 months',
        isDark: isDark,
      ));
    }
    
    return insights;
  }

  Widget _insightItem({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreVisualization() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = _result?.riskScore ?? _computeRiskScore();
    final normalizedScore = (100 - score) / 100; // Invert for health score
    
    Color scoreColor;
    String scoreLabel;
    if (score <= 33) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score <= 66) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Attention';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(
                  'Health Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Circular progress indicator
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: normalizedScore,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(normalizedScore * 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Based on ${currentValues.length} parameters',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}