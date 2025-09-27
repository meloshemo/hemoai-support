import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/web_database_helper.dart';
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
  String gender = 'male'; // canonical code; will be localized/mapped before use
  double bmi = 0.0;
  Color riskColor = Colors.green;
  bool _isLoading = true;
  bool _isSaving = false;

  PreferencesService? _prefsService;
  final WebDatabaseHelper _dbHelper = WebDatabaseHelper.instance;

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
      final loc = Provider.of<LocalizationService>(context, listen: false);
      int? userId = _prefsService?.getCurrentUserId();
      if (userId != null) {
        Map<String, dynamic>? user = await _dbHelper.getUserById(userId);
        if (user != null) {
          setState(() {
            ageController.text = user['age'].toString();
            weightController.text = user['weight'].toString();
            heightController.text = user['height'].toString();
            gender = _mapGenderToCurrentLocale(user['gender']?.toString() ?? 'male', loc);
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
      // Set default gender localized for current locale
      final loc = Provider.of<LocalizationService>(context, listen: false);
      gender = _mapGenderToCurrentLocale(gender, loc);
      _isLoading = false;
    });
  }

  // Map stored gender (possibly TR/EN or code) to current locale label
  String _mapGenderToCurrentLocale(String value, LocalizationService loc) {
    final male = loc.getString('male');
    final female = loc.getString('female');
    final normalized = value.toLowerCase();
    if (normalized == 'erkek' || normalized == 'male') return male;
    if (normalized == 'kadın' || normalized == 'kadin' || normalized == 'female') return female;
    if (value == male || value == female) return value;
    return male; // default
  }

  Future<void> _saveUserData() async {
    if (ageController.text.isEmpty || 
        weightController.text.isEmpty || 
        heightController.text.isEmpty) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('please_fill_all_fields')),
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

        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('info_saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getStringWithParams('save_error', {'error': e.toString()})),
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0D1117) 
          : Colors.white,
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
              tooltip: Provider.of<LocalizationService>(context, listen: false).getString('menu'),
            ),
          ),
          title: Builder(builder: (context){
            final loc = Provider.of<LocalizationService>(context, listen: false);
            return Text(loc.getString('personal_info_entry'));
          }),
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF161B22) 
            : Colors.white,
          foregroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : const Color(0xFFE53E3E),
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
            tooltip: Provider.of<LocalizationService>(context, listen: false).getString('menu'),
          ),
        ),
        title: Builder(builder: (context){
          final loc = Provider.of<LocalizationService>(context, listen: false);
          return Text(loc.getString('personal_info_entry'));
        }),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.white 
          : const Color(0xFFE53E3E),
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
                    
                    Builder(builder: (context){
                      final loc = Provider.of<LocalizationService>(context, listen:false);
                      return Text(
                        loc.getString('enter_your_personal_info'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      );
                    }),
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
                              labelText: Provider.of<LocalizationService>(context, listen:false).getString('age'),
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
                            value: () {
                              final male = Provider.of<LocalizationService>(context, listen:false).getString('male');
                              final female = Provider.of<LocalizationService>(context, listen:false).getString('female');
                              final options = [male, female];
                              return options.contains(gender) ? gender : male;
                            }(),
                            items: () {
                              final male = Provider.of<LocalizationService>(context, listen:false).getString('male');
                              final female = Provider.of<LocalizationService>(context, listen:false).getString('female');
                              return [male, female]
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList();
                            }(),
                            onChanged: (val) {
                              setState(() {
                                gender = val!;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: Provider.of<LocalizationService>(context, listen:false).getString('gender'),
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
                              labelText: Provider.of<LocalizationService>(context, listen:false).getString('weight_kg'),
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
                              labelText: Provider.of<LocalizationService>(context, listen:false).getString('height_cm'),
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
                              child: Builder(builder: (context){
                                final loc = Provider.of<LocalizationService>(context, listen:false);
                                return Text(loc.getString('bmi_calculate'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
                              }),
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
                                      Builder(builder: (context){
                                        final loc = Provider.of<LocalizationService>(context, listen:false);
                                        return Text(
                                          '${loc.getString('bmi_short')}: ${bmi.toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        );
                                      }),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: riskColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Builder(builder: (context){
                                          final loc = Provider.of<LocalizationService>(context, listen:false);
                                          final status = riskColor == Colors.green
                                              ? loc.getString('bmi_status_ideal')
                                              : riskColor == Colors.yellow
                                                  ? loc.getString('bmi_status_normal')
                                                  : loc.getString('bmi_status_risk');
                                          return Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                        }),
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
                          : Builder(builder: (context){
                              final loc = Provider.of<LocalizationService>(context, listen:false);
                              return Text(loc.getString('go_to_hemogram_entry'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
                            }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _saveUserData();
                          Navigator.pushNamed(context, '/dashboard');
                        },
                        icon: const Icon(Icons.dashboard),
                        label: Builder(builder: (context){
                          final loc = Provider.of<LocalizationService>(context, listen:false);
                          return Text(loc.getString('go_to_main_panel'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
