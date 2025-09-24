import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';

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
    setState(() {});
  }
  
  final Map<String, TextEditingController> controllers = {
    'Demir (mcg/dL)': TextEditingController(),
    'Hemoglobin (g/dL)': TextEditingController(),
    'Lökosit (K/uL)': TextEditingController(),
    'Eritrosit (M/uL)': TextEditingController(),
    'Hematokrit (%)': TextEditingController(),
    'Trombosit (K/uL)': TextEditingController(),
    'MCV (fL)': TextEditingController(),
    'MCH (pg)': TextEditingController(),
    'MCHC (g/dL)': TextEditingController(),
    'RDW (%)': TextEditingController(),
    'Nötrofil (%)': TextEditingController(),
    'Lenfosit (%)': TextEditingController(),
    'Monosit (%)': TextEditingController(),
    'Eozinofil (%)': TextEditingController(),
    'Bazofil (%)': TextEditingController(),
  };

  final Map<String, List<double>> referenceRanges = {
    'Demir (mcg/dL)': [60, 170],
    'Hemoglobin (g/dL)': [12, 17],
    'Lökosit (K/uL)': [4, 10],
    'Eritrosit (M/uL)': [4.5, 6],
    'Hematokrit (%)': [38, 50],
    'Trombosit (K/uL)': [150, 400],
    'MCV (fL)': [80, 100],
    'MCH (pg)': [27, 33],
    'MCHC (g/dL)': [32, 36],
    'RDW (%)': [11.5, 14.5],
    'Nötrofil (%)': [40, 75],
    'Lenfosit (%)': [20, 45],
    'Monosit (%)': [2, 10],
    'Eozinofil (%)': [1, 6],
    'Bazofil (%)': [0, 2],
  };

  Color getScaleColor(double value, double low, double high) {
    if (value < low) return Colors.red;
    if (value > high) return Colors.green;
    return Colors.yellow;
  }

  String getScaleText(Color color) {
    if (color == Colors.green) return 'İyi';
    if (color == Colors.yellow) return 'Normal';
    return 'Düşük';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hemogram Sonuçlarını Girin'),
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
                    // Burada OCR entegrasyonu yapılacak
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('OCR ile belge okuma özelliği eklenecek.')),
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text('Belgeyi Fotoğrafla Oku (OCR)'),
                ),
                SizedBox(height: 16),
                ...controllers.keys.map((param) {
                  double value = double.tryParse(controllers[param]!.text) ?? 0.0;
                  double low = referenceRanges[param]![0];
                  double high = referenceRanges[param]![1];
                  Color color = getScaleColor(value, low, high);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controllers[param],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: param,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Değer: ${value.toStringAsFixed(1)}'),
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
                      : const Text(
                          'Kaydet ve Analiz Et',
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
    // Boş alanları kontrol et
    Map<String, double> values = {};
    bool hasValues = false;
    
    controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        try {
          values[key] = double.parse(controller.text);
          hasValues = true;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$key için geçersiz değer girildi'),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
      }
    });

    if (!hasValues) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir değer girin'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      int? userId = _prefsService?.getCurrentUserId();
      if (userId != null) {
        // Hemogram değerlerini veritabanı formatına çevir
        Map<String, double> dbValues = HemogramValues.mapToDatabase(values);
        
        // Risk seviyesini hesapla
        String riskLevel = _calculateRiskLevel(values);
        
        // Veritabanına kaydet
        Map<String, dynamic> testData = {
          'user_id': userId,
          'test_date': DateTime.now().toIso8601String(),
          'risk_level': riskLevel,
          ...dbValues.map((key, value) => MapEntry(key, value)),
        };

        await _dbHelper.insertHemogramTest(testData);
        
        // Preferences'a da kaydet
        if (_prefsService != null) {
          await _prefsService!.setHemogramValues(values);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hemogram değerleri kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );

        // Analiz sayfasına git
        Navigator.pushNamed(context, '/analysis', arguments: values);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: $e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _calculateRiskLevel(Map<String, double> values) {
    int abnormalCount = 0;
    
    values.forEach((parameter, value) {
      List<double>? range = referenceRanges[parameter];
      if (range != null) {
        if (value < range[0] || value > range[1]) {
          abnormalCount++;
        }
      }
    });

    if (abnormalCount == 0) return 'Düşük';
    if (abnormalCount <= 2) return 'Orta';
    return 'Yüksek';
  }
}
