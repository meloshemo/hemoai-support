import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';

class AnalysisScreen extends StatelessWidget {
  AnalysisScreen({super.key});
  final Map<String, double> exampleValues = {
    'iron': 50,
    'hemoglobin': 11.5,
    'white_blood_cells': 8.0,
    'red_blood_cells': 5.0,
    'hematocrit': 40.0,
    'platelets': 200.0,
    'mcv': 85.0,
    'mch': 29.0,
    'mchc': 34.0,
    'rdw': 13.0,
    'neutrophils': 60.0,
    'lymphocytes': 30.0,
    'monocytes': 5.0,
    'eosinophils': 2.0,
    'basophils': 1.0,
  };

  final Map<String, String> altTipAdvice = const {};

  final Map<String, String> dietPrograms = const {};

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

  final Map<String, String> doctorAdvice = const {};

  Color getScaleColor(double value, double low, double high) {
    if (value < low) return Colors.red;
    if (value > high) return Colors.green;
    return Colors.yellow;
  }

  String getScaleText(Color color, LocalizationService loc) {
    if (color == Colors.green) return loc.getString('good');
    if (color == Colors.yellow) return loc.getString('normal');
    return loc.getString('risk');
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      drawer: canPop ? null : const AppDrawer(currentRoute: '/analysis'),
      appBar: AppBar(
        leading: canPop
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop())
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Text(loc.getString('analysis')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(loc.getString('ai_analysis'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ...exampleValues.keys.map((param) {
              double value = exampleValues[param]!;
              double low = referenceRanges[param]![0];
              double high = referenceRanges[param]![1];
              Color color = getScaleColor(value, low, high);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${loc.getString(param)}: ${value.toStringAsFixed(1)}'),
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
                  const SizedBox(height: 8),
                ],
              );
            }),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/diet_program'),
              child: Text(loc.getString('personal_diet_program')),
            ),
          ],
        ),
      ),
    );
  }
}
