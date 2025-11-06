import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _failedAttempts = 0;
  int? _lockUntilMs;

  PreferencesService? _prefsService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _prefsService = await PreferencesService.getInstance();
    final remembered = _prefsService!.getCustomSetting<bool>('remember_me') ?? false;
    final rememberedPhone = _prefsService!.getCustomSetting<String>('remembered_phone') ?? '';
    final failed = _prefsService!.getCustomSetting<int>('login_failed_attempts') ?? 0;
    final lockUntil = _prefsService!.getCustomSetting<int>('login_lock_until');

    if (remembered && rememberedPhone.isNotEmpty) {
      phoneController.text = rememberedPhone;
    }
    _rememberMe = remembered;
    _failedAttempts = failed;
    _lockUntilMs = lockUntil;

    if (!mounted) return;
    setState(() {});
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isLockedOut() {
    if (_lockUntilMs == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < _lockUntilMs!;
  }

  int _lockoutSecondsRemaining() {
    if (_lockUntilMs == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (_lockUntilMs! - now) / 1000;
    return diff > 0 ? diff.ceil() : 0;
  }

  Future<void> _recordFailedAttempt() async {
    _failedAttempts += 1;
    await _prefsService?.saveCustomSettings('login_failed_attempts', _failedAttempts);
    if (_failedAttempts >= 5) {
      final until = DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch;
      _lockUntilMs = until;
      await _prefsService?.saveCustomSettings('login_lock_until', until);
    }
  }

  Future<void> _resetAttempts() async {
    _failedAttempts = 0;
    _lockUntilMs = null;
    await _prefsService?.saveCustomSettings('login_failed_attempts', 0);
    await _prefsService?.saveCustomSettings('login_lock_until', 0);
  }

  bool _validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 11;
  }

  bool _validateEmail(String value) {
    final email = value.trim();
    // Simple RFC 5322-friendly pattern for typical emails
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  Future<void> _toggleRememberMe(bool? value) async {
    final v = value ?? false;
    setState(() {
      _rememberMe = v;
    });
    await _prefsService?.saveCustomSettings('remember_me', v);
    if (v) {
      await _prefsService?.saveCustomSettings('remembered_phone', phoneController.text);
    }
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

    if (_isLockedOut()) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      final secs = _lockoutSecondsRemaining();
      final msg = '${loc.getString('too_many_attempts')} — '
          '${loc.getStringWithParams('try_again_in_seconds', {'seconds': secs.toString()})}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
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
      // Test user check (for convenience)
      if (phoneController.text == '5551234567' && passwordController.text == '1234') {
        String email = '${phoneController.text}@hemoai.com';
        Map<String, dynamic>? existingUser = await _dbHelper.getUser(email);

        if (existingUser == null) {
          final loc = Provider.of<LocalizationService>(context, listen: false);
          Map<String, dynamic> testUser = {
            'name': loc.getString('test_user'),
            'email': email,
            'phone': phoneController.text,
            'password_hash': _hashPassword(passwordController.text),
            'age': 25,
            'gender': 'male',
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

        if (!mounted) return;
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('welcome_test_user')),
            backgroundColor: Colors.green,
          ),
        );

        await _resetAttempts();
        if (_rememberMe) {
          await _prefsService?.saveCustomSettings('remembered_phone', phoneController.text);
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/personal_info');
        return;
      }

      // Normal kullanıcı girişi
      String email = '${phoneController.text}@hemoai.com';
      Map<String, dynamic>? user = await _dbHelper.getUser(email);

      if (user != null) {
        String hashedPassword = _hashPassword(passwordController.text);

        if (user['password_hash'] == hashedPassword) {
          await _prefsService!.setCurrentUserId(user['id']);
          await _prefsService!.setUserInfo(
            user['name'],
            user['email'],
            user['phone'],
          );

          if (!mounted) return;
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('welcome_generic')),
              backgroundColor: Colors.green,
            ),
          );

          await _resetAttempts();
          if (_rememberMe) {
            await _prefsService?.saveCustomSettings('remembered_phone', phoneController.text);
          }
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/personal_info');
        } else {
          await _recordFailedAttempt();
          if (!mounted) return;
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('password_incorrect')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
        }
      } else {
        await _recordFailedAttempt();
        if (!mounted) return;
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('user_not_found')),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('login_error_prefix')}$e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startOtpLogin() async {
    if (_prefsService == null) return;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final phone = phoneController.text.trim();
    if (phone.isEmpty || !_validatePhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('phone_invalid')),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }
    await _sendOtpToPhone(phone);
    await _promptOtpAndVerify(isForPasswordReset: false);
  }

  Future<void> _promptOtpAndVerify({required bool isForPasswordReset}) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final otpController = TextEditingController();
    int resendCount = 0;
    int remaining = 120; // seconds
    Timer? countdown;
    void cancelTimer() {
      countdown?.cancel();
      countdown = null;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // Start countdown on first build
            if (countdown == null && remaining > 0) {
              countdown = Timer.periodic(const Duration(seconds: 1), (t) {
                if (remaining <= 1) {
                  t.cancel();
                  setSheetState(() {
                    remaining = 0;
                    countdown = null;
                  });
                } else {
                  setSheetState(() {
                    remaining -= 1;
                  });
                }
              });
            }
            return AlertDialog(
              title: Text(isForPasswordReset
                  ? loc.getString('set_new_password')
                  : loc.getString('login_with_otp')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isForPasswordReset)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(loc.getString('otp_login_description')),
                    ),
                  TextField(
                    controller: otpController,
                    decoration: InputDecoration(
                      labelText: loc.getString('enter_otp_code'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: remaining > 0
                      ? null
                      : () async {
                          final phone = _prefsService!.getCustomSetting<String>('otp_phone') ?? phoneController.text.trim();
                          await _sendOtpToPhone(phone);
                          setSheetState(() {
                            resendCount += 1;
                            remaining = 120;
                          });
                        },
                  child: Text(
                    remaining > 0
                        ? loc.getStringWithParams('resend_code_in', {'seconds': remaining.toString()})
                        : loc.getString('resend_code'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    cancelTimer();
                    Navigator.pop(ctx, false);
                  },
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () async {
                    final savedCode = _prefsService!.getCustomSetting<String>('otp_code');
                    final expiry = _prefsService!.getCustomSetting<int>('otp_expiry') ?? 0;
                    final now = DateTime.now().millisecondsSinceEpoch;
                    if (now > expiry) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.getString('otp_expired')),
                          backgroundColor: const Color(0xFFE53E3E),
                        ),
                      );
                      return;
                    }
                    if (otpController.text.trim() != (savedCode ?? '')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.getString('invalid_otp')),
                          backgroundColor: const Color(0xFFE53E3E),
                        ),
                      );
                      return;
                    }
                    // Clear OTP once used
                    await _prefsService!.saveCustomSettings('otp_code', '');
                    await _prefsService!.saveCustomSettings('otp_expiry', 0);
                    cancelTimer();
                    Navigator.pop(ctx, true);
                  },
                  child: Text(loc.getString('verify_code')),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (isForPasswordReset) {
        await _promptNewPassword();
      } else {
        await _completeOtpLogin();
      }
    }
  }

  Future<void> _completeOtpLogin() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final phone = _prefsService!.getCustomSetting<String>('otp_phone') ?? phoneController.text.trim();
    final email = '$phone@hemoai.com';
    try {
      final user = await _dbHelper.getUser(email);
      if (user == null) {
        await _recordFailedAttempt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('user_not_found')),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
        return;
      }
      await _prefsService!.setCurrentUserId(user['id']);
      await _prefsService!.setUserInfo(user['name'], user['email'], user['phone']);
      await _resetAttempts();
      if (_rememberMe) {
        await _prefsService?.saveCustomSettings('remembered_phone', phone);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('welcome_generic')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/personal_info');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('login_error_prefix')}$e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    }
  }

  Future<void> _forgotPasswordFlow() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    String method = 'phone'; // 'phone' | 'email'
    final emailController = TextEditingController();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(loc.getString('forgot_password_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.getString('choose_verification_method')),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'phone',
                    groupValue: method,
                    onChanged: (v) => setState(() => method = v ?? 'phone'),
                    title: Text(loc.getString('verify_via_phone')),
                  ),
                  RadioListTile<String>(
                    value: 'email',
                    groupValue: method,
                    onChanged: (v) => setState(() => method = v ?? 'email'),
                    title: Text(loc.getString('verify_via_email')),
                  ),
                  if (method == 'email')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: loc.getString('enter_email_label'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(loc.getString('send_code')),
                ),
              ],
            );
          },
        );
      },
    );

    if (proceed != true) return;

    try {
      if (method == 'phone') {
        final phone = phoneController.text.trim();
        if (phone.isEmpty || !_validatePhone(phone)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('phone_invalid')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
        // Ensure user exists
        final existing = await _dbHelper.findUserByPhone(phone);
        if (existing == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('user_not_found')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
        await _prefsService!.saveCustomSettings('otp_channel', 'phone');
        await _sendOtpToPhone(phone);
      } else {
        final email = emailController.text.trim().isNotEmpty
            ? emailController.text.trim()
            : '${phoneController.text.trim()}@hemoai.com';
        if (email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('email_required')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
        if (!_validateEmail(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('email_invalid')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
        final existing = await _dbHelper.getUser(email);
        if (existing == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('user_not_found')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
          return;
        }
        await _prefsService!.saveCustomSettings('otp_channel', 'email');
        await _sendOtpToEmail(email);
      }

      await _promptOtpAndVerify(isForPasswordReset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('error_prefix')}$e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    }
  }

  Future<void> _promptNewPassword() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final newPassController = TextEditingController();
    final confirmController = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.getString('set_new_password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassController,
                decoration: InputDecoration(labelText: loc.getString('new_password_label')),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(labelText: loc.getString('confirm_new_password')),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                if (newPassController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.getString('password_required')),
                      backgroundColor: const Color(0xFFE53E3E),
                    ),
                  );
                  return;
                }
                if (newPassController.text.length < 4) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.getString('password_min_length')),
                      backgroundColor: const Color(0xFFE53E3E),
                    ),
                  );
                  return;
                }
                if (newPassController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.getString('password_mismatch')),
                      backgroundColor: const Color(0xFFE53E3E),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );

    if (res == true) {
      // Resolve user by the verified channel
      final channel = _prefsService!.getCustomSetting<String>('otp_channel') ?? 'phone';
      Map<String, dynamic>? user;
      if (channel == 'email') {
        final email = _prefsService!.getCustomSetting<String>('otp_email');
        if (email != null && email.isNotEmpty) {
          user = await _dbHelper.getUser(email);
        }
      } else {
        final phone = _prefsService!.getCustomSetting<String>('otp_phone') ?? phoneController.text.trim();
        final email = '$phone@hemoai.com';
        user = await _dbHelper.getUser(email);
      }
      if (user != null) {
        await _dbHelper.updateUser(user['id'], {
          'password_hash': _hashPassword(newPassController.text),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('password_updated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _sendOtpToPhone(String phone) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    final expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await _prefsService!.saveCustomSettings('otp_code', code);
    await _prefsService!.saveCustomSettings('otp_expiry', expiry);
    await _prefsService!.saveCustomSettings('otp_phone', phone);

    final baseMsg = loc.getString('otp_sent');
    final msg = kDebugMode ? '$baseMsg: $code' : baseMsg;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendOtpToEmail(String email) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    final expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await _prefsService!.saveCustomSettings('otp_code', code);
    await _prefsService!.saveCustomSettings('otp_expiry', expiry);
    await _prefsService!.saveCustomSettings('otp_email', email);

    final baseMsg = loc.getString('otp_sent_email');
    final masked = _maskEmail(email);
    final msgShown = kDebugMode ? '$baseMsg: $code' : loc.getStringWithParams('code_sent_to', {'destination': masked});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msgShown),
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

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We will access localization via Provider in Builders where needed
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final loc = Provider.of<LocalizationService>(context);
            return Text(loc.getString('login'));
          },
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
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
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: scheme.primary, width: 2),
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
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final loc = Provider.of<LocalizationService>(context);
                            return TextFormField(
                              controller: phoneController,
                              decoration: InputDecoration(
                                labelText: loc.getString('phone_number_label'),
                                prefixIcon: Icon(Icons.phone, color: scheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.primary, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return loc.getString('phone_required');
                                if (!_validatePhone(value)) return loc.getString('phone_invalid');
                                return null;
                              },
                              onChanged: (v) async {
                                if (_rememberMe) {
                                  await _prefsService?.saveCustomSettings('remembered_phone', v);
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Builder(
                          builder: (context) {
                            final loc = Provider.of<LocalizationService>(context);
                            return TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: loc.getString('password_label'),
                                prefixIcon: Icon(Icons.lock, color: scheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.primary, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? loc.getString('show_password')
                                      : loc.getString('hide_password'),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: scheme.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return loc.getString('password_required');
                                if (value.length < 4) return loc.getString('password_min_length');
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: _toggleRememberMe,
                            ),
                            Builder(
                              builder: (context) {
                                final loc = Provider.of<LocalizationService>(context);
                                return Text(loc.getString('remember_me'));
                              },
                            ),
                            const Spacer(),
                            Builder(
                              builder: (context) {
                                final loc = Provider.of<LocalizationService>(context);
                                return TextButton(
                                  onPressed: _isLoading ? null : _forgotPasswordFlow,
                                  child: Text(
                                    loc.getString('forgot_password'),
                                    style: TextStyle(
                                      color: scheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Test bilgisi
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Builder(
                            builder: (context) {
                              final loc = Provider.of<LocalizationService>(context);
                              return Text(
                                loc.getString('test_credentials_hint'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Giriş Yap Butonları
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: scheme.primary,
                                    foregroundColor: scheme.onPrimary,
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _startOtpLogin,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: scheme.primary,
                                    side: BorderSide(color: scheme.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final loc = Provider.of<LocalizationService>(context);
                                      return Text(loc.getString('login_with_otp'));
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bottom help text area can be expanded later if needed
              ],
            ),
          ),
        ),
      ),
    );
  }
}