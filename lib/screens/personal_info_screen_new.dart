import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

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
  bool _isLoading = true;
  bool _isSaving = false;

  PreferencesService? _prefsService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _prefsService = await PreferencesService.getInstance();
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      int? userId = _prefsService?.getCurrentUserId();
      if (userId != null) {
        Map<String, dynamic>? user = await _dbHelper.getUserById(userId);
        if (user != null) {
          setState(() {
            ageController.text = user['age'].toString();
            weightController.text = user['weight'].toString();
            heightController.text = user['height'].toString();
            gender = user['gender'] ?? 'male';
            bmi = user['bmi'] ?? 0.0;
            riskColor = getRiskColor(bmi);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    
    if (ageController.text.isEmpty || 
        weightController.text.isEmpty || 
        heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getString('please_fill_all_fields')),
          backgroundColor: const Color(0xFFE53E3E),
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
        double weight = double.parse(weightController.text);
        double height = double.parse(heightController.text);
        double calculatedBmi = calculateBMI(weight, height);

        Map<String, dynamic> userData = {
          'age': int.parse(ageController.text),
          'weight': weight,
          'height': height,
          'gender': gender,
          'bmi': calculatedBmi,
        };

        await _dbHelper.updateUser(userId, userData);
        
        // Preferences'a da kaydet
        if (_prefsService != null) {
          await _prefsService!.setPersonalInfo(
            int.parse(ageController.text),
            gender,
            height,
            weight,
          );
        }

        setState(() {
          bmi = calculatedBmi;
          riskColor = getRiskColor(bmi);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService.getString('info_saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizationService.getString('error')}: $e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
            drawer: const AppDrawer(currentRoute: '/personal_info'),
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
              title: Text(localizationService.getString('personal_info')),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF161B22) 
                : Colors.white,
              foregroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : const Color(0xFFE53E3E),
              elevation: 0,
            ),
            body: _isLoading 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizationService.getString('loading'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: Image.asset(
                              'assets/hemoai pic 1.O.jpg',
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: const Color(0xFFE53E3E), width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital,
                                    size: 40,
                                    color: Color(0xFFE53E3E),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          Text(
                            localizationService.getString('enter_personal_info'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53E3E),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Form Container
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF21262D)
                                : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF30363D)
                                  : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: localizationService.getString('age'),
                                    prefixIcon: const Icon(Icons.cake, color: Color(0xFFE53E3E)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: gender,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text(localizationService.getString('male')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text(localizationService.getString('female')),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      gender = val!;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: localizationService.getString('gender'),
                                    prefixIcon: const Icon(Icons.person, color: Color(0xFFE53E3E)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '${localizationService.getString('weight')} (kg)',
                                    prefixIcon: const Icon(Icons.monitor_weight, color: Color(0xFFE53E3E)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '${localizationService.getString('height')} (cm)',
                                    prefixIcon: const Icon(Icons.height, color: Color(0xFFE53E3E)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      double weight = double.tryParse(weightController.text) ?? 0;
                                      double height = double.tryParse(heightController.text) ?? 0;
                                      double newBmi = calculateBMI(weight, height);
                                      setState(() {
                                        bmi = newBmi;
                                        riskColor = getRiskColor(newBmi);
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE53E3E),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      localizationService.getString('calculate_bmi'),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (bmi > 0)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: riskColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: riskColor),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${localizationService.getString('bmi_label')}: ${bmi.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: riskColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _getBMIStatus(bmi, localizationService),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: riskColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveUserData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE53E3E),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          localizationService.getString('save'),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  String _getBMIStatus(double bmi, LocalizationService localizationService) {
    if (bmi < 18.5) {
      return localizationService.getString('underweight');
    } else if (bmi < 25) {
      return localizationService.getString('normal');
    } else if (bmi < 30) {
      return localizationService.getString('overweight');
    } else {
      return localizationService.getString('obese');
    }
  }
}