import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({Key? key}) : super(key: key);

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _debugMessage = '';

  PreferencesService? _prefsService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _prefsService = await PreferencesService.getInstance();
      setState(() {
        _debugMessage = 'Services initialized successfully';
      });
    } catch (e) {
      setState(() {
        _debugMessage = 'Service initialization error: $e';
      });
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _testLogin() async {
    if (_prefsService == null) {
      setState(() {
        _debugMessage = 'Services not ready';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _debugMessage = 'Starting login process...';
    });

    try {
      String email = '${phoneController.text.trim()}@hemoai.com';
      setState(() {
        _debugMessage = 'Checking user: $email';
      });
      
      Map<String, dynamic>? user = await _dbHelper.getUser(email);
      
      if (user != null) {
        setState(() {
          _debugMessage = 'User found: ${user['name']}';
        });
        
        String hashedPassword = _hashPassword(passwordController.text);
        
        if (user['password_hash'] == hashedPassword) {
          setState(() {
            _debugMessage = 'Login successful!';
          });
          
          await _prefsService!.setCurrentUserId(user['id']);
          await _prefsService!.setUserInfo(
            user['name'],
            user['email'],
            user['phone'],
          );
          
          Navigator.pushReplacementNamed(context, '/personal_info');
        } else {
          setState(() {
            _debugMessage = 'Wrong password';
          });
        }
      } else {
        setState(() {
          _debugMessage = 'User not found - need to register first';
        });
      }
    } catch (e) {
      setState(() {
        _debugMessage = 'Login error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRegister() async {
    if (_prefsService == null) {
      setState(() {
        _debugMessage = 'Services not ready';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _debugMessage = 'Starting registration...';
    });

    try {
      String email = '${phoneController.text.trim()}@hemoai.com';
      String hashedPassword = _hashPassword(passwordController.text);
      
      Map<String, dynamic> newUser = {
        'name': 'Test User',
        'email': email,
        'phone': phoneController.text.trim(),
        'password_hash': hashedPassword,
        'age': 25,
        'gender': 'Erkek',
        'height': 170.0,
        'weight': 70.0,
        'bmi': 24.22,
      };

      int userId = await _dbHelper.insertUser(newUser);
      
      if (userId > 0) {
        setState(() {
          _debugMessage = 'Registration successful! User ID: $userId';
        });
        
        await _prefsService!.setCurrentUserId(userId);
        await _prefsService!.setUserInfo('Test User', email, phoneController.text.trim());
      }
    } catch (e) {
      setState(() {
        _debugMessage = 'Registration error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Builder(builder: (context){
          final loc = Provider.of<LocalizationService>(context, listen:false);
          return Text(loc.getString('debug_login_title'));
        }),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Debug message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _debugMessage.isEmpty ? 'Initializing...' : _debugMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            // Phone input
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: Provider.of<LocalizationService>(context, listen:false).getString('phone_number_label'),
                prefixIcon: const Icon(Icons.phone, color: Color(0xFFE53E3E)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Password input
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: Provider.of<LocalizationService>(context, listen:false).getString('password_label'),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFE53E3E)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            
            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Builder(builder: (context){
                          final loc = Provider.of<LocalizationService>(context, listen:false);
                          return Text(loc.getString('test_register'));
                        }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Builder(builder: (context){
                          final loc = Provider.of<LocalizationService>(context, listen:false);
                          return Text(loc.getString('test_login'));
                        }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}