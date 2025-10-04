// ignore_for_file: unnecessary_to_list_in_spreads
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';

class HemogramEntryScreen extends StatefulWidget {
  const HemogramEntryScreen({super.key});

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
    setState(() {});
  }
  
  // Use canonical parameter keys; labels/units are localized at render time
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

  Color getScaleColor(double value, double low, double high) {
    if (value < low) return Colors.red;
    if (value > high) return Colors.green;
    return Colors.yellow;
  }

  String getScaleText(Color color) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    if (color == Colors.green) return loc.getString('good_status');
    if (color == Colors.yellow) return loc.getString('normal_status');
    return loc.getString('low_status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: '/hemogram_entry'),
      appBar: AppBar(
        title: Text(Provider.of<LocalizationService>(context, listen: false).getString('enter_hemogram_values')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ListView(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Burada OCR entegrasyonu yapilacak
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getString('ocr_feature_coming_soon'))),
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text(Provider.of<LocalizationService>(context, listen: false).getString('scan_document_ocr')),
                ),
                SizedBox(height: 16),
                ...controllers.keys.map((paramKey) {
                  final loc = Provider.of<LocalizationService>(context, listen: false);
                  double value = double.tryParse(controllers[paramKey]!.text) ?? 0.0;
                  double low = referenceRanges[paramKey]![0];
                  double high = referenceRanges[paramKey]![1];
                  Color color = getScaleColor(value, low, high);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controllers[paramKey],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${loc.getString(paramKey)} (${units[paramKey]})',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${Provider.of<LocalizationService>(context, listen: false).getString('your_value')}: ${value.toStringAsFixed(1)}'),
                          SizedBox(width: 16),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                getScaleText(color),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                SizedBox(height: 24),
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
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
            : Text(
              Provider.of<LocalizationService>(context, listen: false).getString('save_and_analyze'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveAndAnalyze() async {
  // Bos alanlari kontrol et
    final loc = Provider.of<LocalizationService>(context, listen: false);
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
              content: Text('${loc.getString(key)} ${loc.getString('invalid_value')}'),
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
          content: Text(loc.getString('enter_at_least_one_value')),
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
      // Risk seviyesini hesapla (her zaman)
      final String riskLevel = _calculateRiskLevel(values);

  // UI anahtarlarini DB semasina map et
      final Map<String, double> dbValues = HemogramValues.mapToDatabase(values);

  // Giris yapilmissa veritabanina yaz
      final int? userId = _prefsService?.getCurrentUserId();
      if (userId != null) {
        final Map<String, dynamic> testData = {
          'user_id': userId,
          'test_date': DateTime.now().toIso8601String(),
          'risk_level': riskLevel,
          ...dbValues.map((key, value) => MapEntry(key, value)),
        };
        await _dbHelper.insertHemogramTest(testData);
      }

  // Oturum durumundan bagimsiz olarak Preferences'a yaz
      if (_prefsService != null) {
        await _prefsService!.setHemogramValues(values);
      }

      if (!mounted) return;
  // Basarili bilgilendirme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('hemogram_values_saved')),
          backgroundColor: Colors.green,
        ),
      );

  // Analiz sayfasina git (misafir dahil)
      Navigator.pushNamed(context, '/analysis', arguments: values);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('save_error').replaceFirst('{error}', e.toString())),
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

  String _calculateRiskLevel(Map<String, double> values) {
    int abnormalCount = 0;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    values.forEach((parameter, value) {
      List<double>? range = referenceRanges[parameter];
      if (range != null) {
        if (value < range[0] || value > range[1]) {
          abnormalCount++;
        }
      }
    });

    if (abnormalCount == 0) return loc.getString('low_risk');
    if (abnormalCount <= 2) return loc.getString('moderate_risk');
    return loc.getString('high_risk');
  }
}
