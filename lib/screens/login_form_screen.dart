import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({Key? key}) : super(key: key);

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
    if (_prefsService == null) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('services_not_loaded')),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('enter_phone_password')),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Test kullanıcısı kontrolü (kolaylık için)
      if (phoneController.text == '5551234567' && passwordController.text == '1234') {
        // Test kullanıcısını oluştur (eğer yoksa)
        String email = '${phoneController.text}@hemoai.com';
        Map<String, dynamic>? existingUser = await _dbHelper.getUser(email);
        
        if (existingUser == null) {
          // Test kullanıcısı yoksa oluştur
          Map<String, dynamic> testUser = {
            'name': 'Test Kullanıcısı',
            'email': email,
            'phone': phoneController.text,
            'password_hash': _hashPassword(passwordController.text),
            'age': 25,
            'gender': 'Erkek',
            'height': 175.0,
            'weight': 70.0,
            'bmi': 22.86,
          };
          
          int userId = await _dbHelper.insertUser(testUser);
          await _prefsService!.setCurrentUserId(userId);
          await _prefsService!.setUserInfo(testUser['name'], testUser['email'], testUser['phone']);
        } else {
          await _prefsService!.setCurrentUserId(existingUser['id']);
          await _prefsService!.setUserInfo(existingUser['name'], existingUser['email'], existingUser['phone']);
        }
        
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('welcome_test_user')),
              backgroundColor: Colors.green,
            ),
          );
        
        Navigator.pushReplacementNamed(context, '/personal_info');
        return;
      }

      // Normal kullanıcı girişi
      String email = '${phoneController.text}@hemoai.com';
      
      // Kullanıcıyı veritabanından getir
      Map<String, dynamic>? user = await _dbHelper.getUser(email);
      
      if (user != null) {
        String hashedPassword = _hashPassword(passwordController.text);
        
        if (user['password_hash'] == hashedPassword) {
          // Başarılı giriş
          await _prefsService!.setCurrentUserId(user['id']);
          await _prefsService!.setUserInfo(
            user['name'],
            user['email'],
            user['phone'],
          );
          
            final loc = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.getString('welcome_generic')),
                backgroundColor: Colors.green,
              ),
            );
          
          Navigator.pushReplacementNamed(context, '/personal_info');
        } else {
            final loc = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.getString('password_incorrect')),
                backgroundColor: const Color(0xFFE53E3E),
              ),
            );
        }
      } else {
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('user_not_found')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
      }
    } catch (e) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.getString('login_error_prefix')}$e'),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We will access localization via Provider in Builders where needed
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final loc = Provider.of<LocalizationService>(context);
            return Text(loc.getString('login'));
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo (küçük version)
                Container(
                  margin: const EdgeInsets.only(bottom: 48),
                  child: Image.asset(
                    'assets/hemoai pic 1.O.jpg',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: const Color(0xFFE53E3E), width: 2),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: Color(0xFFE53E3E),
                        ),
                      );
                    },
                  ),
                ),
                
                // Form alanları
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          final loc = Provider.of<LocalizationService>(context);
                          return TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                            labelText: loc.getString('phone_number_label'),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFE53E3E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final loc = Provider.of<LocalizationService>(context);
                          return TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                            labelText: loc.getString('password_label'),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFFE53E3E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                          ),
                        ),
                        obscureText: true,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Test bilgisi
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                          child: Builder(
                            builder: (context) {
                              final loc = Provider.of<LocalizationService>(context);
                              return Text(
                                loc.getString('test_credentials_hint'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                              );
                            },
                          ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Giriş Yap Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Builder(
                                builder: (context) {
                                  final loc = Provider.of<LocalizationService>(context);
                                  return Text(
                                    loc.getString('login'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                  );
                                },
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Forgot Password
                Builder(
                  builder: (context) {
                    final loc = Provider.of<LocalizationService>(context);
                    return TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.getString('forgot_password_coming_soon')),
                            backgroundColor: const Color(0xFFE53E3E),
                          ),
                        );
                      },
                      child: Text(
                        loc.getString('forgot_password'),
                        style: const TextStyle(
                          color: Color(0xFFE53E3E),
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}