import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:country_picker/country_picker.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../services/localization_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

class RegisterScreen extends StatefulWidget {
  final String initialMethod; // 'phone' | 'email'
  const RegisterScreen({super.key, this.initialMethod = 'phone'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  String _selectedDialCode = '+90';
  String _selectedFlag = '🇹🇷';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String method = 'phone';
  bool _isLoading = false;
  PreferencesService? _prefs;
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    method = (widget.initialMethod == 'email') ? 'email' : 'phone';
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await PreferencesService.getInstance();
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool _validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 11;
  }

  bool _validateEmail(String value) {
    final email = value.trim();
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _sendOtpToPhone(String phone) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    final expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await _prefs!.saveCustomSettings('reg_otp_code', code);
    await _prefs!.saveCustomSettings('reg_otp_expiry', expiry);
    await _prefs!.saveCustomSettings('reg_channel', 'phone');
    await _prefs!.saveCustomSettings('reg_phone', phone);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(kDebugMode ? '${loc.getString('otp_sent')}: $code' : loc.getString('otp_sent')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendOtpToEmail(String email) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    final expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await _prefs!.saveCustomSettings('reg_otp_code', code);
    await _prefs!.saveCustomSettings('reg_otp_expiry', expiry);
    await _prefs!.saveCustomSettings('reg_channel', 'email');
    await _prefs!.saveCustomSettings('reg_email', email);
    final masked = _maskEmail(email);
    final msg = kDebugMode ? '${loc.getString('otp_sent_email')}: $code' : loc.getStringWithParams('code_sent_to', {'destination': masked});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final visible = name.length >= 2 ? name.substring(0, 2) : name.substring(0, 1);
    return '$visible***@$domain';
  }

  Future<bool> _promptOtpVerify() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final codeController = TextEditingController();
    int remaining = 120;
    Timer? timer;
    bool verified = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (remaining <= 1) {
              t.cancel();
              setState(() => remaining = 0);
            } else {
              setState(() => remaining -= 1);
            }
          });
          return AlertDialog(
            title: Text(loc.getString('verify_code')),
            content: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: loc.getString('enter_otp_code'),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: remaining > 0
                    ? null
                    : () async {
                        final channel = _prefs!.getCustomSetting<String>('reg_channel') ?? 'phone';
                        if (channel == 'email') {
                          final email = _prefs!.getCustomSetting<String>('reg_email') ?? emailController.text.trim();
                          await _sendOtpToEmail(email);
                        } else {
                          final phone = _prefs!.getCustomSetting<String>('reg_phone') ?? phoneController.text.trim();
                          await _sendOtpToPhone(phone);
                        }
                        setState(() => remaining = 120);
                      },
                child: Text(
                  remaining > 0
                      ? loc.getStringWithParams('resend_code_in', {'seconds': remaining.toString()})
                      : loc.getString('resend_code'),
                ),
              ),
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(ctx);
                },
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              TextButton(
                onPressed: () async {
                  final saved = _prefs!.getCustomSetting<String>('reg_otp_code') ?? '';
                  final expiry = _prefs!.getCustomSetting<int>('reg_otp_expiry') ?? 0;
                  final now = DateTime.now().millisecondsSinceEpoch;
                  if (now > expiry) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.getString('otp_expired')), backgroundColor: const Color(0xFFE53E3E)),
                    );
                    return;
                  }
                  if (codeController.text.trim() != saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.getString('invalid_otp')), backgroundColor: const Color(0xFFE53E3E)),
                    );
                    return;
                  }
                  verified = true;
                  timer?.cancel();
                  Navigator.pop(ctx);
                },
                child: Text(loc.getString('verify_code')),
              ),
            ],
          );
        });
      },
    );
    return verified;
  }

  Future<void> _startRegistration() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (method == 'email') {
        final email = emailController.text.trim();
        final existing = await _db.getUser(email);
        if (existing != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.getString('email_exists')), backgroundColor: const Color(0xFFE53E3E)),
          );
          setState(() => _isLoading = false);
          return;
        }
        await _sendOtpToEmail(email);
      } else {
        final phone = phoneController.text.trim();
        final existing = await _db.findUserByPhone(phone);
        if (existing != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.getString('phone_exists')), backgroundColor: const Color(0xFFE53E3E)),
          );
          setState(() => _isLoading = false);
          return;
        }
        await _sendOtpToPhone(phone);
      }

      final ok = await _promptOtpVerify();
      if (!ok) {
        setState(() => _isLoading = false);
        return;
      }

      // Create user with minimal defaults; complete profile later
      final email = method == 'email' ? emailController.text.trim() : '${phoneController.text.trim()}@hemoai.com';
      final phone = method == 'email' ? 'not_provided' : phoneController.text.trim();
      final userRow = {
        'name': nameController.text.trim(),
        'email': email,
        'phone': phone,
        'password_hash': _hashPassword(passwordController.text.trim()),
        'age': 0,
        'gender': 'male',
        'height': 0.0,
        'weight': 0.0,
        'bmi': 0.0,
      };
      final userId = await _db.insertUser(userRow);
      await _prefs!.setCurrentUserId(userId);
      await _prefs!.setUserInfo(
        userRow['name'] as String,
        userRow['email'] as String,
        userRow['phone'] as String,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.getString('registration_success')), backgroundColor: Colors.green),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/personal_info');
    } catch (e) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.getString('registration_error_prefix')}$e'), backgroundColor: const Color(0xFFE53E3E)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Country _selectedCountry = Country.parse('TR');
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('register_appbar_title')),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Method selection
                  ToggleButtons(
                    isSelected: [method == 'phone', method == 'email'],
                    onPressed: (index) {
                      setState(() {
                        method = index == 1 ? 'email' : 'phone';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(loc.getString('register_with_phone')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(loc.getString('register_with_email')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: loc.getString('name_label')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? loc.getString('name_required') : null,
                  ),
                  const SizedBox(height: 16),

                  if (method == 'phone') ...[
                    Row(
                      children: [
                        // Country picker button
                        TextButton.icon(
                          onPressed: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              onSelect: (Country c) {
                                setState(() {
                                  _selectedCountry = c;
                                  _selectedDialCode = '+${c.phoneCode}';
                                  _selectedFlag = c.flagEmoji;
                                  final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
                                  phoneController.text = '${_selectedDialCode} ${digits}';
                                });
                              },
                            );
                          },
                          icon: Text(_selectedFlag, style: const TextStyle(fontSize: 18)),
                          label: Text('${_selectedCountry.name} (+${_selectedCountry.phoneCode})'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: loc.getString('phone_number_label'),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return loc.getString('phone_required');
                              if (!_validatePhone(value)) return loc.getString('phone_invalid');
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: loc.getString('enter_email_label')),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return loc.getString('email_required');
                        if (!_validateEmail(value)) return loc.getString('email_invalid');
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: loc.getString('password_label')),
                    obscureText: true,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return loc.getString('password_required');
                      if (value.length < 4) return loc.getString('password_min_length');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    decoration: InputDecoration(labelText: loc.getString('password_confirm_label')),
                    obscureText: true,
                    validator: (v) => (v?.trim() ?? '') != (passwordController.text.trim())
                        ? loc.getString('password_mismatch')
                        : null,
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startRegistration,
                      child: _isLoading
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : Text(loc.getString('send_code')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
