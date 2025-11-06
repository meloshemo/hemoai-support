import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';

class HemogramEntryScreen extends StatefulWidget {
  const HemogramEntryScreen({super.key});

  @override
  State<HemogramEntryScreen> createState() => _HemogramEntryScreenState();
}

class _HemogramEntryScreenState extends State<HemogramEntryScreen> {
  // Popular markers (20) controllers
  final Map<String, TextEditingController> controllers = {
    'hemoglobin': TextEditingController(),
    'glucose': TextEditingController(),
    'calcium': TextEditingController(),
    'sodium': TextEditingController(),
    'potassium': TextEditingController(),
    'chloride': TextEditingController(),
    'alt': TextEditingController(),
    'ast': TextEditingController(),
    'ggt': TextEditingController(),
    'total_bilirubin': TextEditingController(),
    'direct_bilirubin': TextEditingController(),
    'crp': TextEditingController(),
    'iron': TextEditingController(),
    'uibc': TextEditingController(),
    'tibc': TextEditingController(),
    'tsh': TextEditingController(),
    'free_t3': TextEditingController(),
    'free_t4': TextEditingController(),
    'vitamin_d3': TextEditingController(),
    'vitamin_b12': TextEditingController(),
  };

  final Map<String, List<double>> referenceRanges = {
    'hemoglobin': [12, 17], // g/dL
    'glucose': [70, 100], // mg/dL (açlık)
    'calcium': [8.6, 10.2], // mg/dL
    'sodium': [135, 145], // mmol/L
    'potassium': [3.5, 5.1], // mmol/L
    'chloride': [98, 107], // mmol/L
    'alt': [7, 56], // U/L
    'ast': [10, 40], // U/L
    'ggt': [9, 48], // U/L
    'total_bilirubin': [0.1, 1.2], // mg/dL
    'direct_bilirubin': [0.0, 0.3], // mg/dL
    'crp': [0, 5], // mg/L
    'iron': [60, 170], // µg/dL
    'uibc': [110, 370], // µg/dL
    'tibc': [240, 450], // µg/dL
    'tsh': [0.4, 4.0], // µIU/mL
    'free_t3': [2.0, 4.4], // pg/mL
    'free_t4': [0.8, 1.8], // ng/dL
    'vitamin_d3': [20, 50], // ng/mL
    'vitamin_b12': [200, 900], // pg/mL
  };

  Color getScaleColor(double value, double low, double high) {
    if (value < low) return Colors.red;
    if (value > high) return Colors.green;
    return Colors.yellow;
  }

  String getScaleText(Color color, LocalizationService loc) {
    if (color == Colors.green) return loc.getString('good');
    if (color == Colors.yellow) return loc.getString('normal');
    return loc.getString('low');
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (final controller in controllers.values) {
      controller.dispose();
    }
    controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('hemogram_entry'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ListView(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.getString('ocr_desktop_placeholder'))),
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text(loc.getString('scan_document')),
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
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: loc.getString(param),
                          border: const OutlineInputBorder(),
                          errorText: controllers[param]!.text.isNotEmpty
                              ? Validators.validateNumericRange(
                                  controllers[param]!.text,
                                  min: referenceRanges[param]![0] * 0.5,
                                  max: referenceRanges[param]![1] * 2.0,
                                  fieldName: loc.getString(param),
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${loc.getString('value')}: ${value.toStringAsFixed(1)}'),
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
                                getScaleText(color, loc),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                }),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final Map<String, double> values = {};
                    controllers.forEach((key, ctrl) {
                      final t = ctrl.text.trim();
                      if (t.isNotEmpty) {
                        final v = double.tryParse(t.replaceAll(',', '.'));
                        if (v != null) values[key] = v;
                      }
                    });
                    Navigator.pushNamed(context, '/analysis', arguments: values);
                  },
                  child: Text(loc.getString('analysis')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
