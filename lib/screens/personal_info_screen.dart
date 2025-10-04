import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  String gender = 'male';
  double bmi = 0.0;
  Color riskColor = Colors.green;

  double calculateBMI(double weight, double height) {
    if (height == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  Color getRiskColor(double bmi) {
    if (bmi < 18.5) return Colors.red;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.yellow;
    return Colors.red;
  }

  @override
  void dispose() {
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      drawer: canPop ? null : const Drawer(child: SizedBox()),
      appBar: AppBar(
        leading: canPop
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop())
            : null,
        title: Text(loc.getString('personal_info')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.getString('age_label'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  items: ['male', 'female']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g == 'male' ? loc.getString('male') : loc.getString('female'))))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      gender = val!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: loc.getString('gender'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.getString('weight_kg'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.getString('height_cm'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    double weight = double.tryParse(weightController.text) ?? 0;
                    double height = double.tryParse(heightController.text) ?? 0;
                    double newBmi = calculateBMI(weight, height);
                    setState(() {
                      bmi = newBmi;
                      riskColor = getRiskColor(newBmi);
                    });
                  },
                  child: Text(loc.getString('calculate_bmi')),
                ),
                SizedBox(height: 16),
                bmi > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${loc.getString('bmi')}: ${bmi.toStringAsFixed(1)}'),
                          SizedBox(width: 16),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: riskColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                riskColor == Colors.green
                                    ? loc.getString('good')
                                    : riskColor == Colors.yellow
                                        ? loc.getString('status_normal')
                                        : loc.getString('risk'),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/hemogram_entry');
                  },
                  child: Text(loc.getString('continue')),
                ),
              ],
            ),
      ),
    );
  }
}
