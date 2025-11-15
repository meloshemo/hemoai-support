import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';

class VerificationService {
  VerificationService._internal();

  static final VerificationService _instance = VerificationService._internal();

  factory VerificationService() => _instance;

  final Random _random = Random();

  Future<Map<String, dynamic>?> _getActiveUserRow() async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) return null;
    return await DatabaseHelper.instance.getUserById(userId);
  }

  Future<bool> ensureEmailVerified(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    if (!context.mounted) return false;
    if (prefs.isEmailVerified()) {
      return true;
    }

    final userRow = await _getActiveUserRow();
    if (!context.mounted) return false;
    if (userRow == null) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      _showSnackBar(
        context,
        loc.getString('login_required'),
        Colors.red,
      );
      return false;
    }

    final TextEditingController emailController = TextEditingController(
      text: (userRow['email'] ?? '').toString().contains('@hemoai.com')
          ? ''
          : (userRow['email'] ?? '').toString(),
    );
    final TextEditingController codeController = TextEditingController();
    bool codeSent = false;
    int secondsRemaining = 0;
    Timer? timer;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final loc = Provider.of<LocalizationService>(sheetCtx, listen: false);
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> sendCode() async {
              final validation =
                  Validators.validateEmail(emailController.text, loc: loc);
              if (validation != null) {
                _showSnackBar(ctx, validation, Colors.red);
                return;
              }
              final email = emailController.text.trim();
              final existing = await DatabaseHelper.instance.getUser(email);
              if (!ctx.mounted) return;
              if (existing != null &&
                  (existing['id'] as num?)?.toInt() !=
                      (userRow['id'] as num?)?.toInt()) {
                _showSnackBar(
                  ctx,
                  loc.getString('email_exists'),
                  Colors.red,
                );
                return;
              }
              await _storeOtp(
                prefs: prefs,
                keyPrefix: 'verify_email',
                value: email,
              );
              if (!ctx.mounted) return;
              setState(() {
                codeSent = true;
                secondsRemaining = 120;
              });
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                setState(() {
                  if (secondsRemaining <= 1) {
                    secondsRemaining = 0;
                    timer?.cancel();
                  } else {
                    secondsRemaining -= 1;
                  }
                });
              });
              _showSnackBar(
                ctx,
                kDebugMode
                    ? '${loc.getString('otp_sent_email')}: ${prefs.getCustomSetting<String>('verify_email_code')}'
                    : loc.getStringWithParams('code_sent_to', {
                        'destination': emailController.text.trim(),
                      }),
                Colors.green,
              );
            }

            Future<void> verify() async {
              final success = await _validateOtp(
                prefs: prefs,
                keyPrefix: 'verify_email',
                inputCode: codeController.text.trim(),
              );
              if (!ctx.mounted) return;
              if (!success) {
                _showSnackBar(
                  ctx,
                  loc.getString('invalid_otp'),
                  Colors.red,
                );
                return;
              }
              final verifiedEmail =
                  prefs.getCustomSetting<String>('verify_email_value') ??
                      emailController.text.trim();

              await DatabaseHelper.instance.updateUser(
                (userRow['id'] as num).toInt(),
                {
                  'email': verifiedEmail,
                  'email_verified': 1,
                },
              );

              final updatedUser = await DatabaseHelper.instance.getUserById(
                (userRow['id'] as num).toInt(),
              );
              if (!context.mounted || !ctx.mounted) return;
              final phone =
                  (updatedUser?['phone'] ?? userRow['phone'] ?? '').toString();
              final phoneVerified = (updatedUser?['phone_verified'] ??
                      userRow['phone_verified'] ??
                      0) ==
                  1;
              await prefs.setUserInfo(
                (updatedUser?['name'] ?? userRow['name'] ?? '').toString(),
                verifiedEmail,
                phone,
                emailVerified: true,
                phoneVerified: phoneVerified,
              );
              await _clearOtp(prefs: prefs, keyPrefix: 'verify_email');
              if (!context.mounted || !ctx.mounted) return;
              _showSnackBar(
                context,
                loc.getString('email_verification_success'),
                Colors.green,
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(true);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.getString('verify_email_title'),
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.getString('verify_email_description'),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: loc.getString('enter_email_label'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (codeSent)
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: loc.getString('enter_otp_code'),
                        counterText: '',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: codeSent ? null : sendCode,
                          child: Text(codeSent
                              ? loc.getStringWithParams('resend_code_in', {
                                  'seconds': secondsRemaining.toString(),
                                })
                              : loc.getString('send_code')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (codeSent)
                        Expanded(
                          child: FilledButton(
                            onPressed: verify,
                            child: Text(loc.getString('verify_code')),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );

    timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    return result ?? false;
  }

  Future<bool> ensurePhoneVerified(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    if (!context.mounted) return false;
    if (prefs.isPhoneVerified()) {
      return true;
    }

    final userRow = await _getActiveUserRow();
    if (!context.mounted) return false;
    if (userRow == null) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      _showSnackBar(
        context,
        loc.getString('login_required'),
        Colors.red,
      );
      return false;
    }

    final TextEditingController phoneController = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    bool codeSent = false;
    int secondsRemaining = 0;
    Timer? timer;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final loc = Provider.of<LocalizationService>(sheetCtx, listen: false);
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> sendCode() async {
              final phoneValidation =
                  Validators.validatePhone(phoneController.text, loc: loc);
              if (phoneValidation != null) {
                _showSnackBar(ctx, phoneValidation, Colors.red);
                return;
              }
              final digits = _normalizePhoneDigits(phoneController.text);
              final existing =
                  await DatabaseHelper.instance.findUserByPhone(digits);
              if (!ctx.mounted) return;
              if (existing != null &&
                  (existing['id'] as num?)?.toInt() !=
                      (userRow['id'] as num?)?.toInt()) {
                _showSnackBar(
                  ctx,
                  loc.getString('phone_exists'),
                  Colors.red,
                );
                return;
              }

              await _storeOtp(
                prefs: prefs,
                keyPrefix: 'verify_phone',
                value: digits,
              );
              if (!ctx.mounted) return;
              setState(() {
                codeSent = true;
                secondsRemaining = 120;
              });
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                setState(() {
                  if (secondsRemaining <= 1) {
                    secondsRemaining = 0;
                    timer?.cancel();
                  } else {
                    secondsRemaining -= 1;
                  }
                });
              });
              _showSnackBar(
                ctx,
                kDebugMode
                    ? '${loc.getString('otp_sent')}: ${prefs.getCustomSetting<String>('verify_phone_code')}'
                    : loc.getString('otp_sent'),
                Colors.green,
              );
            }

            Future<void> verify() async {
              final success = await _validateOtp(
                prefs: prefs,
                keyPrefix: 'verify_phone',
                inputCode: codeController.text.trim(),
              );
              if (!ctx.mounted) return;
              if (!success) {
                _showSnackBar(
                  ctx,
                  loc.getString('invalid_otp'),
                  Colors.red,
                );
                return;
              }
              final verifiedPhone =
                  prefs.getCustomSetting<String>('verify_phone_value') ??
                      _normalizePhoneDigits(phoneController.text);

              await DatabaseHelper.instance.updateUser(
                (userRow['id'] as num).toInt(),
                {
                  'phone': verifiedPhone,
                  'phone_verified': 1,
                },
              );

              final updatedUser = await DatabaseHelper.instance.getUserById(
                (userRow['id'] as num).toInt(),
              );
              if (!context.mounted || !ctx.mounted) return;
              final email =
                  (updatedUser?['email'] ?? userRow['email'] ?? '').toString();
              final emailVerified = (updatedUser?['email_verified'] ??
                      userRow['email_verified'] ??
                      0) ==
                  1;
              await prefs.setUserInfo(
                (updatedUser?['name'] ?? userRow['name'] ?? '').toString(),
                email,
                verifiedPhone,
                emailVerified: emailVerified,
                phoneVerified: true,
              );
              await _clearOtp(prefs: prefs, keyPrefix: 'verify_phone');
              if (!context.mounted || !ctx.mounted) return;
              _showSnackBar(
                context,
                loc.getString('phone_verification_success'),
                Colors.green,
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(true);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.getString('verify_phone_title'),
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.getString('verify_phone_description'),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: loc.getString('phone_number_label'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (codeSent)
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: loc.getString('enter_otp_code'),
                        counterText: '',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: codeSent ? null : sendCode,
                          child: Text(codeSent
                              ? loc.getStringWithParams('resend_code_in', {
                                  'seconds': secondsRemaining.toString(),
                                })
                              : loc.getString('send_code')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (codeSent)
                        Expanded(
                          child: FilledButton(
                            onPressed: verify,
                            child: Text(loc.getString('verify_code')),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );

    timer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    return result ?? false;
  }

  Future<void> _storeOtp({
    required PreferencesService prefs,
    required String keyPrefix,
    required String value,
  }) async {
    final code = List.generate(6, (_) => _random.nextInt(10)).join();
    final expiry =
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await prefs.saveCustomSettings('${keyPrefix}_code', code);
    await prefs.saveCustomSettings('${keyPrefix}_expiry', expiry);
    await prefs.saveCustomSettings('${keyPrefix}_value', value);
  }

  Future<bool> _validateOtp({
    required PreferencesService prefs,
    required String keyPrefix,
    required String inputCode,
  }) async {
    final expected = prefs.getCustomSetting<String>('${keyPrefix}_code') ?? '';
    final expiry = prefs.getCustomSetting<int>('${keyPrefix}_expiry') ?? 0;
    if (expected.isEmpty || inputCode != expected) {
      return false;
    }
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      return false;
    }
    return true;
  }

  Future<void> _clearOtp({
    required PreferencesService prefs,
    required String keyPrefix,
  }) async {
    await prefs.saveCustomSettings('${keyPrefix}_code', '');
    await prefs.saveCustomSettings('${keyPrefix}_expiry', 0);
    await prefs.saveCustomSettings('${keyPrefix}_value', '');
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  String _normalizePhoneDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
