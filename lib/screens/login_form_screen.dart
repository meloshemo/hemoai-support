// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../services/premium_service.dart';
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
    final remembered =
        _prefsService!.getCustomSetting<bool>('remember_me') ?? false;
    final rememberedPhone =
        _prefsService!.getCustomSetting<String>('remembered_phone') ?? '';
    final failed =
        _prefsService!.getCustomSetting<int>('login_failed_attempts') ?? 0;
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
    await _prefsService?.saveCustomSettings(
        'login_failed_attempts', _failedAttempts);
    if (_failedAttempts >= 5) {
      final until = DateTime.now()
          .add(const Duration(seconds: 60))
          .millisecondsSinceEpoch;
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

  String _normalizePhoneDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
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
      await _prefsService?.saveCustomSettings(
          'remembered_phone', phoneController.text);
    }
  }

  Future<void> _login() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final premiumService = Provider.of<PremiumService>(context, listen: false);

    if (_prefsService == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.getString('services_not_loaded')),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    if (_isLockedOut()) {
      final secs = _lockoutSecondsRemaining();
      final msg = '${loc.getString('too_many_attempts')} — '
          '${loc.getStringWithParams('try_again_in_seconds', {
            'seconds': secs.toString()
          })}';
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      messenger.showSnackBar(
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
      // Normalize phone number first
      final normalizedPhone = _normalizePhoneDigits(phoneController.text);
      
      // Test user check (for convenience) - only if exact match
      final passwordText = passwordController.text.trim();
      if (normalizedPhone == '5551234567' && passwordText == '1234') {
        final email = '$normalizedPhone@hemoai.com';
        final testUserName = loc.getString('test_user');
        Map<String, dynamic>? existingUser =
            await _dbHelper.findUserByPhone(normalizedPhone);

        if (existingUser == null) {
          // Create new test user
          Map<String, dynamic> testUser = {
            'name': testUserName,
            'email': email,
            'phone': normalizedPhone,
            'password_hash': _hashPassword(passwordText),
            'age': 25,
            'gender': 'male',
            'height': 175.0,
            'weight': 70.0,
            'bmi': 22.86,
            'email_verified': 0,
            'phone_verified': 1,
          };

          int userId = await _dbHelper.insertUser(testUser);
          if (userId <= 0) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text('${loc.getString('login_error_prefix')}Failed to create test user (userId: $userId)'),
                backgroundColor: const Color(0xFFE53E3E),
              ),
            );
            return;
          }
          
          try {
            if (_prefsService == null) {
              throw Exception('PreferencesService is null');
            }
            await _prefsService!.setCurrentUserId(userId);
            if (kDebugMode) {
              debugPrint('Test user: Set current user ID to $userId');
            }
            
            // Ensure all values are non-null before calling setUserInfo
            final safeName = testUserName.isNotEmpty ? testUserName : 'Test User';
            final safeEmail = email.isNotEmpty ? email : '$normalizedPhone@hemoai.com';
            final safePhone = normalizedPhone.isNotEmpty ? normalizedPhone : '5551234567';
            
            await _prefsService!.setUserInfo(
              safeName,
              safeEmail,
              safePhone,
              emailVerified: false,
              phoneVerified: true,
            );
            if (kDebugMode) {
              debugPrint('Test user: User info saved successfully');
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('Test user: Error saving user info: $e');
              debugPrint('Stack trace: $stackTrace');
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text('${loc.getString('login_error_prefix')}Failed to save user info: $e'),
                backgroundColor: const Color(0xFFE53E3E),
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
        } else {
          // Use existing test user
          final userId = existingUser['id'];
          if (userId == null) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text('${loc.getString('login_error_prefix')}User ID is missing from existing user'),
                backgroundColor: const Color(0xFFE53E3E),
              ),
            );
            return;
          }
          
          try {
            if (_prefsService == null) {
              throw Exception('PreferencesService is null');
            }
            await _prefsService!.setCurrentUserId(userId);
            if (kDebugMode) {
              debugPrint('Test user (existing): Set current user ID to $userId');
            }
            
            final emailVerified = (existingUser['email_verified'] ?? 0) == 1;
            final phoneVerified = (existingUser['phone_verified'] ?? 0) == 1;
            
            // Ensure all values are non-null before calling setUserInfo
            final safeName = (existingUser['name'] ?? testUserName).toString();
            final safeEmail = (existingUser['email'] ?? email).toString();
            final safePhone = (existingUser['phone'] ?? normalizedPhone).toString();
            
            if (safeName.isEmpty || safeEmail.isEmpty || safePhone.isEmpty) {
              throw Exception('User data contains empty values: name=$safeName, email=$safeEmail, phone=$safePhone');
            }
            
            await _prefsService!.setUserInfo(
              safeName,
              safeEmail,
              safePhone,
              emailVerified: emailVerified,
              phoneVerified: phoneVerified,
            );
            if (kDebugMode) {
              debugPrint('Test user (existing): User info saved successfully');
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('Test user (existing): Error saving user info: $e');
              debugPrint('Stack trace: $stackTrace');
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text('${loc.getString('login_error_prefix')}Failed to save user info: $e'),
                backgroundColor: const Color(0xFFE53E3E),
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
        }

        if (!mounted) return;
        final locMessage = loc.getString('welcome_test_user');
        messenger.showSnackBar(
          SnackBar(
            content: Text(locMessage),
            backgroundColor: Colors.green,
          ),
        );

        await _resetAttempts();
        if (_rememberMe) {
          await _prefsService?.saveCustomSettings(
              'remembered_phone', phoneController.text);
        }
        // Revalidate subscription on login (non-blocking)
        try {
          await premiumService.revalidateNow();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Premium revalidation failed (non-critical): $e');
          }
        }
        if (!mounted) return;
        
        // Navigate after successful login
        try {
          await _navigateAfterAuth('/personal_info');
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            messenger.showSnackBar(
              SnackBar(
                content: Text('${loc.getString('login_error_prefix')}Navigation failed: $e'),
                backgroundColor: const Color(0xFFE53E3E),
              ),
            );
          }
          return;
        }
        return;
      }

      // Normal kullanıcı girişi
      if (normalizedPhone.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(loc.getString('phone_invalid')),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
        return;
      }
      Map<String, dynamic>? user =
          await _dbHelper.findUserByPhone(normalizedPhone);

      if (user != null) {
        String hashedPassword = _hashPassword(passwordController.text);
        final storedHash = user['password_hash']?.toString() ?? '';

        if (storedHash == hashedPassword) {
          final userId = user['id'];
          if (userId == null) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text('${loc.getString('login_error_prefix')}User ID is missing'),
                backgroundColor: const Color(0xFFE53E3E),
              ),
            );
            return;
          }
          
          await _prefsService!.setCurrentUserId(userId);
          final emailVerified = (user['email_verified'] ?? 0) == 1;
          final phoneVerified = (user['phone_verified'] ?? 0) == 1;
          await _prefsService!.setUserInfo(
            (user['name'] ?? '').toString(),
            (user['email'] ?? '').toString(),
            (user['phone'] ?? '').toString(),
            emailVerified: emailVerified,
            phoneVerified: phoneVerified,
          );

          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(loc.getString('welcome_generic')),
              backgroundColor: Colors.green,
            ),
          );

          await _resetAttempts();
          if (_rememberMe) {
            await _prefsService?.saveCustomSettings(
                'remembered_phone', phoneController.text);
          }
          // Revalidate subscription on login
          try {
            await premiumService.revalidateNow();
          } catch (_) {}
          if (!mounted) return;
          await _navigateAfterAuth('/personal_info');
        } else {
          await _recordFailedAttempt();
          if (!mounted) return;
          // Debug: Show more info in debug mode
          final debugMsg = kDebugMode
              ? '${loc.getString('password_incorrect')} (User found but password mismatch)'
              : loc.getString('password_incorrect');
          messenger.showSnackBar(
            SnackBar(
              content: Text(debugMsg),
              backgroundColor: const Color(0xFFE53E3E),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        await _recordFailedAttempt();
        if (!mounted) return;
        // Debug: Show more info in debug mode
        final debugMsg = kDebugMode
            ? '${loc.getString('user_not_found')} (Phone: $normalizedPhone)'
            : loc.getString('user_not_found');
        messenger.showSnackBar(
          SnackBar(
            content: Text(debugMsg),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Login error caught: $e');
        debugPrint('Stack trace: $stack');
      }
      if (!mounted) return;
      // Provide a friendlier localized fallback when we get an opaque null error
      final message = e.toString().contains('Unexpected null value')
          ? loc.getString('unexpected_error_occurred')
          : e.toString();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${loc.getString('login_error_prefix')}$message'),
          backgroundColor: const Color(0xFFE53E3E),
          duration: const Duration(seconds: 5),
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
                          final phone = _prefsService!
                                  .getCustomSetting<String>('otp_phone') ??
                              phoneController.text.trim();
                          await _sendOtpToPhone(phone);
                          setSheetState(() {
                            remaining = 120;
                          });
                        },
                  child: Text(
                    remaining > 0
                        ? loc.getStringWithParams(
                            'resend_code_in', {'seconds': remaining.toString()})
                        : loc.getString('resend_code'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    cancelTimer();
                    Navigator.pop(ctx, false);
                  },
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () async {
                    final savedCode =
                        _prefsService!.getCustomSetting<String>('otp_code');
                    final expiry =
                        _prefsService!.getCustomSetting<int>('otp_expiry') ?? 0;
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
    final phoneDigits = _prefsService!.getCustomSetting<String>('otp_phone') ??
        phoneController.text.trim();
    final normalized = _normalizePhoneDigits(phoneDigits);
    try {
      final user = await _dbHelper.findUserByPhone(normalized);
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
      final emailVerified = (user['email_verified'] ?? 0) == 1;
      final phoneVerified = (user['phone_verified'] ?? 0) == 1;
      await _prefsService!.setUserInfo(
        user['name'],
        user['email'],
        user['phone'],
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
      );
      await _resetAttempts();
      if (_rememberMe) {
        await _prefsService?.saveCustomSettings('remembered_phone', normalized);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('welcome_generic')),
          backgroundColor: Colors.green,
        ),
      );
      // Revalidate subscription on login
      try {
        final premium = Provider.of<PremiumService>(context, listen: false);
        await premium.revalidateNow();
      } catch (_) {}
      if (!mounted) return;
      await _navigateAfterAuth('/personal_info');
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
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'phone',
                        label: Text(loc.getString('verify_via_phone')),
                        icon: const Icon(Icons.phone),
                      ),
                      ButtonSegment<String>(
                        value: 'email',
                        label: Text(loc.getString('verify_via_email')),
                        icon: const Icon(Icons.email),
                      ),
                    ],
                    selected: {method},
                    onSelectionChanged: (selection) {
                      final choice =
                          selection.isNotEmpty ? selection.first : 'phone';
                      setState(() => method = choice);
                    },
                    showSelectedIcon: false,
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
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
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
        final existing =
            await _dbHelper.findUserByPhone(_normalizePhoneDigits(phone));
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
            : '${_normalizePhoneDigits(phoneController.text.trim())}@hemoai.com';
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
                decoration: InputDecoration(
                    labelText: loc.getString('new_password_label')),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                    labelText: loc.getString('confirm_new_password')),
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
      final channel =
          _prefsService!.getCustomSetting<String>('otp_channel') ?? 'phone';
      Map<String, dynamic>? user;
      if (channel == 'email') {
        final email = _prefsService!.getCustomSetting<String>('otp_email');
        if (email != null && email.isNotEmpty) {
          user = await _dbHelper.getUser(email);
        }
      } else {
        final phoneRaw = _prefsService!.getCustomSetting<String>('otp_phone') ??
            phoneController.text.trim();
        final digits = _normalizePhoneDigits(phoneRaw);
        user = await _dbHelper.findUserByPhone(digits);
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
    final expiry =
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await _prefsService!.saveCustomSettings('otp_code', code);
    await _prefsService!.saveCustomSettings('otp_expiry', expiry);
    final normalized = _normalizePhoneDigits(phone);
    await _prefsService!.saveCustomSettings('otp_phone', normalized);

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
    final expiry =
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await _prefsService!.saveCustomSettings('otp_code', code);
    await _prefsService!.saveCustomSettings('otp_expiry', expiry);
    await _prefsService!.saveCustomSettings('otp_email', email);

    final baseMsg = loc.getString('otp_sent_email');
    final masked = _maskEmail(email);
    final msgShown = kDebugMode
        ? '$baseMsg: $code'
        : loc.getStringWithParams('code_sent_to', {'destination': masked});
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
    final visible =
        name.length >= 2 ? name.substring(0, 2) : name.substring(0, 1);
    return '$visible***@$domain';
  }

  Future<void> _navigateAfterAuth(String defaultRoute) async {
    try {
      final prefs = _prefsService ?? await PreferencesService.getInstance();
      if (!mounted) return;
      if (prefs.isMedicalConsentAccepted()) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, defaultRoute);
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/medical_consent',
          arguments: {'nextRoute': defaultRoute},
        );
      }
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('login_error_prefix')}Navigation error: $e'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
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
                            final loc =
                                Provider.of<LocalizationService>(context);
                            return TextFormField(
                              controller: phoneController,
                              decoration: InputDecoration(
                                labelText: loc.getString('phone_number_label'),
                                prefixIcon:
                                    Icon(Icons.phone, color: scheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: scheme.primary, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) {
                                  return loc.getString('phone_required');
                                }
                                if (!_validatePhone(value)) {
                                  return loc.getString('phone_invalid');
                                }
                                return null;
                              },
                              onChanged: (v) async {
                                if (_rememberMe) {
                                  await _prefsService?.saveCustomSettings(
                                      'remembered_phone', v);
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Builder(
                          builder: (context) {
                            final loc =
                                Provider.of<LocalizationService>(context);
                            return TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: loc.getString('password_label'),
                                prefixIcon:
                                    Icon(Icons.lock, color: scheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: scheme.primary, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? loc.getString('show_password')
                                      : loc.getString('hide_password'),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
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
                                if (value.isEmpty) {
                                  return loc.getString('password_required');
                                }
                                if (value.length < 4) {
                                  return loc.getString('password_min_length');
                                }
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
                                final loc =
                                    Provider.of<LocalizationService>(context);
                                return Text(loc.getString('remember_me'));
                              },
                            ),
                            const Spacer(),
                            Builder(
                              builder: (context) {
                                final loc =
                                    Provider.of<LocalizationService>(context);
                                return TextButton(
                                  onPressed:
                                      _isLoading ? null : _forgotPasswordFlow,
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
                            border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Builder(
                            builder: (context) {
                              final loc =
                                  Provider.of<LocalizationService>(context);
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        )
                                      : Builder(
                                          builder: (context) {
                                            final loc = Provider.of<
                                                LocalizationService>(context);
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
                                      final loc =
                                          Provider.of<LocalizationService>(
                                              context);
                                      return Text(
                                          loc.getString('login_with_otp'));
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
