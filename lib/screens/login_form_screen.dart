import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servisler henüz yüklenmedi, lütfen bekleyin'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }

    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen telefon numarası ve şifre girin'),
          backgroundColor: Color(0xFFE53E3E),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hoş geldiniz Test Kullanıcısı!'),
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hoş geldiniz!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushReplacementNamed(context, '/personal_info');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şifre hatalı!'),
              backgroundColor: Color(0xFFE53E3E),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bulunamadı!'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş yapılırken hata oluştu: $e'),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3), // Mavi
              Color(0xFF64B5F6), // Açık mavi
              Color(0xFFE3F2FD), // Çok açık mavi
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst kısım - Geri butonu
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Giriş Yap',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44), // IconButton genişliği kadar boşluk
                  ],
                ),
              ),
              
              // Ana içerik
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Image.asset(
                              'assets/hemoai pic 1.O.jpg',
                              width: 140,
                              height: 140,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(70),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital,
                                    size: 70,
                                    color: Color(0xFF2196F3),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Form kartı
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Telefon numarası alanı
                                TextField(
                                  controller: phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Telefon Numarası',
                                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF2196F3)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 20),
                                
                                // Şifre alanı
                                TextField(
                                  controller: passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Şifre',
                                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF2196F3)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 16),
                                
                                // Test bilgisi
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                                  ),
                                  child: const Text(
                                    '💡 Test için:\nTelefon: 5551234567\nŞifre: 1234',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2196F3),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Giriş butonu
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2196F3),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 4,
                                      shadowColor: const Color(0xFF2196F3).withOpacity(0.3),
                                    ),
                                    child: _isLoading 
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        )
                                      : const Text(
                                          'Giriş Yap',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Şifremi unuttum
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Şifre sıfırlama özelliği yakında eklenecek'),
                                  backgroundColor: Color(0xFF2196F3),
                                ),
                              );
                            },
                            child: const Text(
                              'Şifremi Unuttum',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}