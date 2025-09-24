import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  String gender = 'Erkek';
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
            gender = user['gender'] ?? 'Erkek';
            bmi = user['bmi'] ?? 0.0;
            riskColor = getRiskColor(bmi);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    if (ageController.text.isEmpty || 
        weightController.text.isEmpty || 
        heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
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
          const SnackBar(
            content: Text('Bilgiler başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Kişisel Bilgi Girişi'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE53E3E),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kişisel Bilgi Girişi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
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
                    
                    const Text(
                      'Kişisel Bilgilerinizi Girin',
                      style: TextStyle(
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
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Yaş',
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
                            items: ['Erkek', 'Kadın']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                gender = val!;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Cinsiyet',
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
                              labelText: 'Kilo (kg)',
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
                              labelText: 'Boy (cm)',
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
                              child: const Text('VKİ Hesapla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          bmi > 0
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE53E3E)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'VKİ: ${bmi.toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: riskColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          riskColor == Colors.green
                                              ? 'İdeal'
                                              : riskColor == Colors.yellow
                                                  ? 'Normal'
                                                  : 'Risk',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () async {
                          await _saveUserData();
                          Navigator.pushNamed(context, '/hemogram_entry');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53E3E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Devam Et', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
