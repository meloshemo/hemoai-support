import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';

class HemogramEntryScreen extends StatefulWidget {
  const HemogramEntryScreen({Key? key}) : super(key: key);

  @override
  State<HemogramEntryScreen> createState() => _HemogramEntryScreenState();
}

class _HemogramEntryScreenState extends State<HemogramEntryScreen> {
  bool _isSaving = false;
  PreferencesService? _prefsService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _prefsService = await PreferencesService.getInstance();
    if (!mounted) return;
    setState(() {});
  }

  // Controllers for canonical parameter keys
  final Map<String, TextEditingController> controllers = {
    'iron': TextEditingController(),
    'hemoglobin': TextEditingController(),
    'white_blood_cells': TextEditingController(),
    'red_blood_cells': TextEditingController(),
    'hematocrit': TextEditingController(),
    'platelets': TextEditingController(),
    'mcv': TextEditingController(),
    'mch': TextEditingController(),
    'mchc': TextEditingController(),
    'rdw': TextEditingController(),
    'neutrophil': TextEditingController(),
    'lymphocyte': TextEditingController(),
    'monocyte': TextEditingController(),
    'eosinophil': TextEditingController(),
    'basophil': TextEditingController(),
  };

  final Map<String, List<double>> referenceRanges = {
    'iron': [60, 170],
    'hemoglobin': [12, 17],
    'white_blood_cells': [4, 10],
    'red_blood_cells': [4.5, 6],
    'hematocrit': [38, 50],
    'platelets': [150, 400],
    'mcv': [80, 100],
    'mch': [27, 33],
    'mchc': [32, 36],
    'rdw': [11.5, 14.5],
    'neutrophil': [40, 75],
    'lymphocyte': [20, 45],
    'monocyte': [2, 10],
    'eosinophil': [1, 6],
    'basophil': [0, 2],
  };

  final Map<String, String> units = {
    'iron': 'mcg/dL',
    'hemoglobin': 'g/dL',
    'white_blood_cells': 'K/uL',
    'red_blood_cells': 'M/uL',
    'hematocrit': '%',
    'platelets': 'K/uL',
    'mcv': 'fL',
    'mch': 'pg',
    'mchc': 'g/dL',
    'rdw': '%',
    'neutrophil': '%',
    'lymphocyte': '%',
    'monocyte': '%',
    'eosinophil': '%',
    'basophil': '%',
  };

  String getValueStatus(double value, double low, double high, LocalizationService localizationService) {
    if (value < low) return localizationService.getString('low');
    if (value > high) return localizationService.getString('high');
    return localizationService.getString('normal');
  }

  Color getValueColor(double value, double low, double high) {
    if (value < low || value > high) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return Directionality(
          textDirection: localizationService.textDirection,
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0D1117)
                : Colors.white,
            drawer: const AppDrawer(currentRoute: '/hemogram_entry'),
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF0F6FC)
                        : const Color(0xFFE53E3E),
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: localizationService.getString('menu'),
                ),
              ),
              title: Text(localizationService.getString('enter_hemogram_values')),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF161B22)
                  : Colors.white,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFFE53E3E),
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // OCR Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localizationService.getString('ocr_feature_coming_soon')),
                            backgroundColor: const Color(0xFFE53E3E),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        localizationService.getString('scan_document_ocr'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF21262D)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF30363D)
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizationService.getString('hemogram_info'),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hemogram Parameters
                  ...controllers.keys.map((paramKey) {
                    double value = double.tryParse(controllers[paramKey]!.text) ?? 0.0;
                    double low = referenceRanges[paramKey]![0];
                    double high = referenceRanges[paramKey]![1];
                    String status = value > 0 ? getValueStatus(value, low, high, localizationService) : '';
                    Color statusColor = value > 0 ? getValueColor(value, low, high) : Colors.grey;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF21262D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF30363D)
                              : Colors.grey.shade300,
                        ),
                        boxShadow: Theme.of(context).brightness == Brightness.dark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Parameter Name and Unit
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${localizationService.getString(paramKey)} (${units[paramKey]})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (value > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Input Field
                          TextField(
                            controller: controllers[paramKey],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: localizationService.getString('your_value'),
                              hintText: '${low.toString()} - ${high.toString()}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 8),

                          // Reference Range
                          Text(
                            '${localizationService.getString('reference_values')}: ${low.toString()} - ${high.toString()} ${units[paramKey]}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndAnalyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(localizationService.getString('loading')),
                              ],
                            )
                          : Text(
                              localizationService.getString('save_and_analyze'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAndAnalyze() async {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);

    // Parse numeric inputs
    Map<String, double> values = {};
    bool hasValues = false;

    controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        try {
          values[key] = double.parse(controller.text);
          hasValues = true;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizationService.getString(key)} ${localizationService.getString('invalid_value')}'),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
      }
    });

    if (!hasValues) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getString('enter_at_least_one_value')),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      // Always compute risk level
      String riskLevel = _calculateRiskLevel(values, localizationService);

      // Map UI keys to DB schema keys
      final dbValues = HemogramValues.mapToDatabase(values);

      // Insert into DB only if a user is logged in
      int? userId = _prefsService?.getCurrentUserId();
      if (userId != null) {
        Map<String, dynamic> testData = {
          'user_id': userId,
          'test_date': DateTime.now().toIso8601String(),
          'risk_level': riskLevel,
          ...dbValues.map((key, value) => MapEntry(key, value)),
        };
        await _dbHelper.insertHemogramTest(testData);
      }

      // Persist latest values for all users (including guests)
      if (_prefsService != null) {
        await _prefsService!.setHemogramValues(values);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getString('hemogram_values_saved')),
          backgroundColor: Colors.green,
        ),
      );

      // Always navigate to analysis (guest-friendly)
      Navigator.pushNamed(context, '/analysis', arguments: values);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizationService.getString('error')}: $e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _calculateRiskLevel(Map<String, double> values, LocalizationService localizationService) {
    int abnormalCount = 0;

    values.forEach((parameter, value) {
      List<double>? range = referenceRanges[parameter];
      if (range != null) {
        if (value < range[0] || value > range[1]) {
          abnormalCount++;
        }
      }
    });

    if (abnormalCount == 0) return localizationService.getString('low');
    if (abnormalCount <= 2) return localizationService.getString('medium');
    return localizationService.getString('high');
  }
}

// Static class for canonical->DB mapping
class HemogramValues {
  static Map<String, double> mapToDatabase(Map<String, double> values) {
    // Map canonical UI keys to SQLite column names
    final Map<String, String> keyMap = {
      'white_blood_cells': 'leukocyte',
      'red_blood_cells': 'erythrocyte',
      'platelets': 'platelet',
      // Passthrough: iron, hemoglobin, hematocrit, mcv, mch, mchc, rdw,
      // neutrophil, lymphocyte, monocyte, eosinophil, basophil
    };

    final Map<String, double> mapped = {};

    values.forEach((key, value) {
      final target = keyMap[key] ?? key;
      mapped[target] = value;
    });

    return mapped;
  }
}