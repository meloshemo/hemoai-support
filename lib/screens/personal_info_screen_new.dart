import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';

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

  // Get health status color based on BMI and hemogram values
  Future<Color> getHealthStatusColor(double bmi) async {
    if (bmi <= 0) return Colors.grey; // No data
    
    int? userId = _prefsService?.getCurrentUserId();
    if (userId != null) {
      try {
        Map<String, dynamic>? latestTest = await _dbHelper.getLatestHemogramTest(userId);
        if (latestTest != null) {
          // Count abnormal values
          int abnormalCount = 0;
          int totalCount = 0;
          
          // Check key health markers
          Map<String, List<double>> ranges = {
            'hemoglobin': [12.0, 17.0],
            'iron': [60.0, 170.0],
            'white_blood_cells': [4.0, 11.0],
            'platelets': [150.0, 400.0],
            'hematocrit': [36.0, 52.0],
          };
          
          ranges.forEach((key, range) {
            double? value = latestTest[key]?.toDouble();
            if (value != null) {
              totalCount++;
              if (value < range[0] || value > range[1]) {
                abnormalCount++;
              }
            }
          });
          
          // Health status logic
          double abnormalRatio = totalCount > 0 ? abnormalCount / totalCount : 0.0;
          
          // Consider BMI in the decision
          bool bmiHealthy = bmi >= 18.5 && bmi < 25;
          bool bmiModerate = (bmi >= 25 && bmi < 30) || (bmi < 18.5);
          
          if (bmiHealthy && abnormalRatio < 0.3) {
            return Colors.green; // Most values good, BMI healthy
          } else if (abnormalRatio >= 0.7) {
            return Colors.red; // Most values bad
          } else if (abnormalRatio >= 0.3 || bmiModerate) {
            return Colors.orange; // Some bad values or BMI issue
          }
        }
      } catch (e) {
        debugPrint('Error calculating health status: $e');
      }
    }
    
    // Fallback to BMI-only color
    return getRiskColor(bmi);
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
          if (!mounted) return;
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
  debugPrint('Error loading user data: $e');
    }
    
    if (!mounted) return;
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

        if (!mounted) return;
        setState(() {
          bmi = calculatedBmi;
          riskColor = getRiskColor(bmi);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService.getString('info_saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Directionality(
          textDirection: localizationService.textDirection,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: const AppDrawer(currentRoute: '/personal_info'),
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: localizationService.getString('menu'),
                ),
              ),
              title: Text(localizationService.getString('personal_info')),
              backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
              foregroundColor: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
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
                          // 3D Health Avatar with dynamic coloring
                          FutureBuilder<Color>(
                            future: getHealthStatusColor(bmi),
                            builder: (context, snapshot) {
                              Color avatarColor = snapshot.data ?? Colors.green;
                              return Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(60),
                                        boxShadow: [
                                          BoxShadow(
                                            color: avatarColor.withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          avatarColor,
                                          BlendMode.saturation,
                                        ),
                                        child: Lottie.asset(
                                          'assets/lottie/Robot-Bot 3D.json',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.contain,
                                          repeat: true,
                                          animate: true,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: theme.cardColor,
                                                borderRadius: BorderRadius.circular(60),
                                                border: Border.all(color: avatarColor, width: 3),
                                              ),
                                              child: Icon(
                                                Icons.favorite,
                                                size: 60,
                                                color: avatarColor,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    localizationService.getString('health_status_indicator'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: avatarColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                          
                          Text(
                            localizationService.getString('enter_personal_info'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Form Container
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scheme.outline,
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: localizationService.getString('age'),
                                    prefixIcon: Icon(Icons.cake, color: scheme.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: scheme.primary, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: gender,
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
                                    prefixIcon: Icon(Icons.person, color: scheme.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: scheme.primary, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '${localizationService.getString('weight')} (${localizationService.getString('unit_kg')})',
                                    prefixIcon: Icon(Icons.monitor_weight, color: scheme.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: scheme.primary, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '${localizationService.getString('height')} (${localizationService.getString('unit_cm')})',
                                    prefixIcon: Icon(Icons.height, color: scheme.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: scheme.primary, width: 2),
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
                                      backgroundColor: scheme.primary,
                                      foregroundColor: scheme.onPrimary,
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
                                      backgroundColor: scheme.primary,
                                      foregroundColor: scheme.onPrimary,
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