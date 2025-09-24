import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Email formatına çevirme (telefon + @hemoai.com)
      String email = '${phoneController.text.trim()}@hemoai.com';
      
      // Kullanıcı zaten var mı kontrol et
      Map<String, dynamic>? existingUser = await _dbHelper.getUser(email);
      
      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu telefon numarası ile kayıtlı kullanıcı zaten mevcut!'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
        return;
      }

      // Yeni kullanıcı oluştur
      String hashedPassword = _hashPassword(passwordController.text);
      
      Map<String, dynamic> newUser = {
        'name': nameController.text.trim(),
        'email': email,
        'phone': phoneController.text.trim(),
        'password_hash': hashedPassword,
        'age': 25, // Varsayılan değer, personal_info'da güncellenecek
        'gender': 'Erkek', // Varsayılan değer, personal_info'da güncellenecek
        'height': 170.0, // Varsayılan değer
        'weight': 70.0, // Varsayılan değer
        'bmi': 24.22, // Hesaplanacak
      };

      int userId = await _dbHelper.insertUser(newUser);
      
      if (userId > 0) {
        // Başarılı kayıt
        if (_prefsService != null) {
          await _prefsService!.setCurrentUserId(userId);
          await _prefsService!.setUserInfo(
            nameController.text.trim(),
            email,
            phoneController.text.trim(),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Profilinizi tamamlayın.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Personal info sayfasına yönlendir
        Navigator.pushReplacementNamed(context, '/personal_info');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt sırasında hata oluştu: $e'),
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
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Üye Ol'),
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
                
                // Başlık
                const Text(
                  'Üye Olun',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'HemoAI ile sağlığınızı takip edin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Form container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Ad Soyad',
                            prefixIcon: const Icon(Icons.person, color: Color(0xFFE53E3E)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen ad soyad giriniz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Telefon Numarası',
                            hintText: '05XXXXXXXXX',
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen telefon numarası giriniz';
                            }
                            if (value.length < 10) {
                              return 'Geçerli telefon numarası giriniz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen şifre giriniz';
                            }
                            if (value.length < 4) {
                              return 'Şifre en az 4 karakter olmalı';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Şifre Tekrar',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE53E3E)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen şifreyi tekrar giriniz';
                            }
                            if (value != passwordController.text) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      
                        // Üye Ol Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
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
                              : const Text(
                                  'Üye Ol',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Gizlilik bildirimi
                Text(
                  'Üye olarak Gizlilik Politikası ve Kullanım Şartlarını kabul etmiş olursunuz.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
