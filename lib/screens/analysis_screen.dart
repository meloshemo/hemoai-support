import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/web_database_helper.dart';
import '../services/database_helper.dart';
import '../services/audit_log_service.dart';
import '../services/preferences_service.dart';
import '../services/export_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';
import 'export_options_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final Map<String, double> hemogramValues;

  const AnalysisScreen({
    Key? key,
    required this.hemogramValues,
  }) : super(key: key);

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final WebDatabaseHelper _dbHelper;
  final PreferencesService _prefsService = PreferencesService();
  final ExportService _exportService = ExportService();
  
  Map<String, double> currentValues = {};
  List<Map<String, dynamic>> testHistory = [];
  bool _isExporting = false;

  // Reference ranges keyed by canonical parameter codes
  final Map<String, Map<String, double>> referenceRanges = {
    'hemoglobin': {'min': 12.0, 'max': 17.0},
    'iron': {'min': 60.0, 'max': 170.0},
    'white_blood_cells': {'min': 4.0, 'max': 11.0},
    'platelets': {'min': 150.0, 'max': 450.0},
    'hematocrit': {'min': 35.0, 'max': 50.0},
    'mcv': {'min': 80.0, 'max': 100.0},
    'mch': {'min': 27.0, 'max': 32.0},
    'mchc': {'min': 32.0, 'max': 36.0},
    'rdw': {'min': 11.5, 'max': 14.5},
    'ferritin': {'min': 15.0, 'max': 150.0},
  };

  @override
  void initState() {
    super.initState();
    _dbHelper = WebDatabaseHelper.instance;
    currentValues = Map.from(widget.hemogramValues);
    _loadTestHistory();
    // Background audit: analysis viewed
    AuditLogService().logAction('analysis_viewed', data: {
      'params_count': currentValues.length,
    });
  }

  Future<void> _loadTestHistory() async {
    try {
      int? userId = await _prefsService.getCurrentUserId();
      if (userId != null) {
        // Prefer unified DatabaseHelper for cross-platform storage
        final db = DatabaseHelper.instance;
        final rows = await db.getHemogramTests(userId);
        setState(() {
          testHistory = rows;
        });
      }
    } catch (e) {
      print('Error loading test history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF0D1117) 
        : Colors.grey[50],
      drawer: const AppDrawer(currentRoute: '/analysis'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: localizationService.getString('menu'),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        title: Text(
          localizationService.getString('analysis_results'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : const Color(0xFFE53E3E),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _loadTestHistory();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Ana Analiz Başlığı
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
                    color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
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
                    _getOverallAssessment(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final rl = _getRiskLevel();
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.withValues(alpha: 0.9), width: 1.2),
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
            
            // Hemogram Değerleri Listesi
            _buildParametersList(localizationService),
            
            const SizedBox(height: 24),
            
            // Genel Değerlendirme
            _buildOverallEvaluation(localizationService),
            
            const SizedBox(height: 24),
            
            // Öneriler
            _buildRecommendations(localizationService),
            
            const SizedBox(height: 24),
            
            // Test Geçmişi
            if (testHistory.isNotEmpty) _buildTestHistory(localizationService),
            
            const SizedBox(height: 24),
            
            // Alt Butonlar
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
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
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
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
    );
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
            ...currentValues.entries.map((entry) {
              return _buildParameterRow(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String parameter, double value) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final range = referenceRanges[parameter];
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
                color: statusColor.withValues(alpha: 0.2),
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
          color: cardColor.withValues(alpha: 0.1),
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
    List<String> recommendations = _generateRecommendations();
    
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

  String _localizedParamName(String raw) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // If already canonical key, translate directly
    const canonicalKeys = {
      'hemoglobin',
      'iron',
      'white_blood_cells',
      'red_blood_cells',
      'hematocrit',
      'platelets',
      'mcv',
      'mch',
      'mchc',
      'rdw',
      'ferritin',
      'neutrophil',
      'lymphocyte',
      'monocyte',
      'eosinophil',
      'basophil',
    };
    if (canonicalKeys.contains(raw)) return loc.getString(raw);

    final lower = raw.toLowerCase();
    if (lower.contains('hemoglobin')) return loc.getString('hemoglobin');
    if (lower.contains('demir') || lower.contains('iron')) return loc.getString('iron');
    if (lower.contains('lökosit') || lower.contains('lokosit') || lower.contains('wbc')) return loc.getString('white_blood_cells');
    if (lower.contains('eritrosit') || lower.contains('rbc') || lower.contains('red blood')) return loc.getString('red_blood_cells');
    if (lower.contains('trombosit') || lower.contains('platelet') || lower.contains('plt')) return loc.getString('platelets');
    if (lower.contains('hematokrit') || lower.contains('hct')) return loc.getString('hematocrit');
    if (lower.contains('mcv')) return loc.getString('mcv');
    if (lower.contains('mchc')) return loc.getString('mchc');
    if (lower.contains('mch')) return loc.getString('mch');
    if (lower.contains('rdw')) return loc.getString('rdw');
    if (lower.contains('ferritin')) return loc.getString('ferritin');
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
    final rl = riskLevel.toLowerCase();
    Color riskColor;
    if (rl == 'yüksek' || rl == 'yuksek' || rl == 'high') {
      riskColor = Colors.red;
    } else if (rl == 'orta' || rl == 'medium') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }
    String riskLabel;
    if (rl == 'yüksek' || rl == 'yuksek' || rl == 'high') {
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
                  color: riskColor.withValues(alpha: 0.2),
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
    
  // Hemoglobin kontrolü
  double? hb = currentValues['hemoglobin'];
    if (hb != null && hb < 12.0) {
      recommendations.add(Provider.of<LocalizationService>(context, listen: false).getString('hemoglobin_low_recommendation'));
    }
    
  // Demir kontrolü
  double? iron = currentValues['iron'];
    if (iron != null && iron < 60.0) {
      recommendations.add(Provider.of<LocalizationService>(context, listen: false).getString('iron_low_recommendation'));
    }
    
  // Lökosit kontrolü
  double? wbc = currentValues['white_blood_cells'];
    if (wbc != null && wbc > 11.0) {
      recommendations.add(Provider.of<LocalizationService>(context, listen: false).getString('wbc_high_recommendation'));
    }
    
    // Genel öneriler
    if (recommendations.isEmpty) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
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
                // Burada paylaşım işlevi olacak
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

  // ===== RAPOR VE DIŞA AKTARMA ÖZELLİKLERİ =====
  
  void _generatePDFReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('pdf_report_dialog_title')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Provider.of<LocalizationService>(context, listen: false).getString('pdf_report_intro')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Provider.of<LocalizationService>(context, listen: false).getString('report_content_heading'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('report_content_item_values')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('report_content_item_ai_analysis')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('report_content_item_health_tips')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('report_content_item_risk_assessment')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('report_content_item_date') + ': ' + Provider.of<LocalizationService>(context, listen: false).formatDate(DateTime.now())),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _simulatePDFGeneration(context);
              },
              icon: const Icon(Icons.download),
              label: Text(Provider.of<LocalizationService>(context, listen: false).getString('create_pdf_button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _simulatePDFGeneration(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('pdf_generating')),
            ],
          ),
        );
      },
    );

    // 2 saniye sonra tamamlandı mesajı
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('pdf_generated_success')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _exportToExcel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_export_title')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_export_intro')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_content_heading'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('excel_content_item_all_params')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('excel_content_item_normal_ranges')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('excel_content_item_status_analysis')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('excel_content_item_test_history')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('excel_content_item_charts')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _simulateExcelExport(context);
              },
              icon: const Icon(Icons.download),
              label: Text(Provider.of<LocalizationService>(context, listen: false).getString('create_excel_button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _simulateExcelExport(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_generating')),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('excel_generated_success')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _sendEmail(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.email, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('email_send_title')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Provider.of<LocalizationService>(context, listen: false).getString('email_send_intro')),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('email_address_label'),
                  hintText: Provider.of<LocalizationService>(context, listen: false).getString('email_address_hint'),
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Provider.of<LocalizationService>(context, listen: false).getString('email_content_heading'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('email_content_item_pdf')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('email_content_item_analysis_summary')),
                    Text('• ' + Provider.of<LocalizationService>(context, listen: false).getString('email_content_item_health_tips')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _simulateEmailSend(context, emailController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Provider.of<LocalizationService>(context, listen: false).getString('email_invalid')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: Text(Provider.of<LocalizationService>(context, listen: false).getString('email_send_button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _simulateEmailSend(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(Provider.of<LocalizationService>(context, listen: false).getString('email_sending')),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(Provider.of<LocalizationService>(context, listen: false).getStringWithParams('email_sent_success', {'email': email}))),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  // Navigate to Export Options Screen
  void _navigateToExportOptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExportOptionsScreen(
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
}