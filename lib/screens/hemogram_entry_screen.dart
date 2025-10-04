import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class HemogramEntryScreen extends StatelessWidget {
  HemogramEntryScreen({super.key});
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
    'neutrophils': TextEditingController(),
    'lymphocytes': TextEditingController(),
    'monocytes': TextEditingController(),
    'eosinophils': TextEditingController(),
    'basophils': TextEditingController(),
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
    'neutrophils': [40, 75],
    'lymphocytes': [20, 45],
    'monocytes': [2, 10],
    'eosinophils': [1, 6],
    'basophils': [0, 2],
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
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc.getString(param),
                          border: OutlineInputBorder(),
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
                    Navigator.pushNamed(context, '/analysis');
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
