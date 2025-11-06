import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Professional email service for sending transactional emails via SendGrid
/// Supports secure API key storage, retry mechanism, rate limiting, and error handling
/// 
/// Configuration:
/// 1. Set SENDGRID_API_KEY via --dart-define or environment variable
/// 2. API key will be stored securely in flutter_secure_storage
/// 3. Falls back to test mode if API key is not configured
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const String _sendGridApiUrl = 'https://api.sendgrid.com/v3/mail/send';
  static const String _secureStorageKey = 'sendgrid_api_key';
  static const String _prefsFromEmailKey = 'email_from_email';
  static const String _prefsFromNameKey = 'email_from_name';
  
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  bool _isInitialized = false;
  bool _isTestMode = false;
  String _apiKey = '';
  String _fromEmail = 'noreply@hemoai.com';
  String _fromName = 'HemoAI';
  
  // Rate limiting
  final List<DateTime> _sentEmails = [];
  static const int _maxEmailsPerMinute = 10;
  static const int _maxEmailsPerHour = 100;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  bool get isConfigured => _apiKey.isNotEmpty && !_isTestMode && _isInitialized;
  bool get isTestMode => _isTestMode;
  
  /// Initialize email service with secure API key storage
  /// Priority: 1. Parameters, 2. Environment variables, 3. Secure storage, 4. Test mode
  Future<void> initialize({
    String? apiKey,
    String? fromEmail,
    String? fromName,
    bool? testMode,
    bool preferSecureStorage = true,
  }) async {
    if (_isInitialized && !kDebugMode) {
      _logger.i('EmailService already initialized');
      return;
    }
    
    try {
      // 1. Try parameters first
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKey = apiKey;
        if (preferSecureStorage) {
          await _secureStorage.write(key: _secureStorageKey, value: apiKey);
          _logger.i('✅ API key saved to secure storage');
        }
      } else {
        // 2. Try environment variables
        final envApiKey = const String.fromEnvironment('SENDGRID_API_KEY', defaultValue: '');
        if (envApiKey.isNotEmpty) {
          _apiKey = envApiKey;
          if (preferSecureStorage) {
            await _secureStorage.write(key: _secureStorageKey, value: envApiKey);
            _logger.i('✅ API key from environment saved to secure storage');
          }
        } else if (preferSecureStorage) {
          // 3. Try secure storage
          final storedKey = await _secureStorage.read(key: _secureStorageKey);
          if (storedKey != null && storedKey.isNotEmpty) {
            _apiKey = storedKey;
            _logger.i('✅ API key loaded from secure storage');
          }
        }
      }
      
      // Configure from email and name
      final prefs = await SharedPreferences.getInstance();
      
      if (fromEmail != null && fromEmail.isNotEmpty) {
        _fromEmail = fromEmail;
        await prefs.setString(_prefsFromEmailKey, fromEmail);
      } else {
        final envFromEmail = const String.fromEnvironment('SENDGRID_FROM_EMAIL', defaultValue: '');
        if (envFromEmail.isNotEmpty) {
          _fromEmail = envFromEmail;
        } else {
          final storedFromEmail = prefs.getString(_prefsFromEmailKey);
          if (storedFromEmail != null && storedFromEmail.isNotEmpty) {
            _fromEmail = storedFromEmail;
          }
        }
      }
      
      if (fromName != null && fromName.isNotEmpty) {
        _fromName = fromName;
        await prefs.setString(_prefsFromNameKey, fromName);
      } else {
        final envFromName = const String.fromEnvironment('SENDGRID_FROM_NAME', defaultValue: 'HemoAI');
        if (envFromName.isNotEmpty) {
          _fromName = envFromName;
        } else {
          final storedFromName = prefs.getString(_prefsFromNameKey);
          if (storedFromName != null && storedFromName.isNotEmpty) {
            _fromName = storedFromName;
          }
        }
      }
      
      // Determine mode
      _isTestMode = testMode ?? _apiKey.isEmpty;
      
      // Validate configuration
      if (!_isTestMode) {
        final isValid = await _validateApiKey(_apiKey);
        if (!isValid) {
          _logger.w('⚠️ Invalid API key format, falling back to test mode');
          _isTestMode = true;
        }
      }
      
      _isInitialized = true;
      
      if (_isTestMode) {
        _logger.w('📧 EmailService initialized in TEST MODE (no emails will be sent)');
        _logger.w('   To enable production mode, set SENDGRID_API_KEY environment variable or call initialize(apiKey: "...")');
      } else {
        _logger.i('✅ EmailService initialized in PRODUCTION MODE');
        _logger.i('   From: $_fromName <$_fromEmail>');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize EmailService: $e', error: e, stackTrace: stackTrace);
      _isTestMode = true; // Fallback to test mode on error
      _isInitialized = true;
    }
  }
  
  /// Validate API key format (basic check)
  Future<bool> _validateApiKey(String key) async {
    if (key.isEmpty) return false;
    // SendGrid API keys start with "SG."
    if (!key.startsWith('SG.')) {
      return false;
    }
    // Basic length check (SendGrid keys are typically 69 characters)
    if (key.length < 60 || key.length > 100) {
      return false;
    }
    return true;
  }
  
  /// Check rate limits
  bool _checkRateLimit() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    _sentEmails.removeWhere((time) => time.isBefore(oneHourAgo));
    
    final recentMinute = _sentEmails.where((time) => time.isAfter(oneMinuteAgo)).length;
    final recentHour = _sentEmails.length;
    
    if (recentMinute >= _maxEmailsPerMinute) {
      _logger.w('⚠️ Rate limit exceeded: $_maxEmailsPerMinute emails per minute');
      return false;
    }
    
    if (recentHour >= _maxEmailsPerHour) {
      _logger.w('⚠️ Rate limit exceeded: $_maxEmailsPerHour emails per hour');
      return false;
    }
    
    return true;
  }
  
  /// Record email sent (for rate limiting)
  void _recordEmailSent() {
    _sentEmails.add(DateTime.now());
  }

  /// Send password reset email with retry mechanism and rate limiting
  Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String resetToken,
    required String locale,
  }) async {
    if (!_isInitialized) {
      _logger.w('⚠️ EmailService not initialized. Call initialize() first.');
      return false;
    }
    
    if (!_isTestMode && !_checkRateLimit()) {
      return false;
    }

    final resetUrl = 'https://hemoai.com/reset-password?token=$resetToken&email=${Uri.encodeComponent(toEmail)}';
    final subject = _getPasswordResetSubject(locale);
    final htmlBody = _getPasswordResetHtml(resetUrl, locale);
    final textBody = _getPasswordResetText(resetUrl, locale);

    if (_isTestMode) {
      // Test mode: log the email details
      _logger.i('📧 [TEST MODE] Password Reset Email:');
      _logger.i('   To: $toEmail');
      _logger.i('   Subject: $subject');
      _logger.i('   Reset URL: $resetUrl');
      _logger.i('   Token: ${resetToken.substring(0, 8)}...');
      return true; // Simulate success
    }

    // Send with retry mechanism
    return await _sendEmailWithRetry(
      toEmail: toEmail,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
      emailType: 'password_reset',
    );
  }
  
  /// Send email with retry mechanism
  Future<bool> _sendEmailWithRetry({
    required String toEmail,
    required String subject,
    required String htmlBody,
    required String textBody,
    String emailType = 'general',
  }) async {
    int attempt = 0;
    Exception? lastError;
    
    while (attempt < _maxRetries) {
      try {
        attempt++;
        
        if (attempt > 1) {
          _logger.i('📧 Retry attempt $attempt/$_maxRetries for $emailType to $toEmail');
          await Future.delayed(_retryDelay * attempt); // Exponential backoff
        }
        
        final response = await http.post(
          Uri.parse(_sendGridApiUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'personalizations': [
              {
                'to': [
                  {'email': toEmail}
                ],
                'subject': subject,
              }
            ],
            'from': {
              'email': _fromEmail,
              'name': _fromName,
            },
            'content': [
              {
                'type': 'text/plain',
                'value': textBody,
              },
              {
                'type': 'text/html',
                'value': htmlBody,
              },
            ],
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('SendGrid API request timed out');
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _recordEmailSent();
          _logger.i('✅ $emailType email sent successfully to $toEmail');
          return true;
        } else {
          final errorBody = response.body;
          _logger.w('❌ SendGrid API error (${response.statusCode}): $errorBody');
          
          // Parse error response
          try {
            final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
            final errors = errorJson['errors'] as List<dynamic>?;
            if (errors != null && errors.isNotEmpty) {
              final error = errors.first as Map<String, dynamic>;
              final message = error['message'] as String?;
              _logger.w('   Error message: $message');
            }
          } catch (_) {
            // Ignore JSON parsing errors
          }
          
          // Retry on 5xx errors, fail on 4xx
          if (response.statusCode >= 500 && attempt < _maxRetries) {
            lastError = Exception('SendGrid server error: ${response.statusCode}');
            continue;
          } else {
            return false;
          }
        }
      } catch (e, stackTrace) {
        lastError = e is Exception ? e : Exception(e.toString());
        _logger.w('❌ Email send attempt $attempt failed: $e');
        
        if (attempt < _maxRetries) {
          continue;
        } else {
          _logger.e('❌ All email send attempts failed for $emailType to $toEmail',
                    error: lastError, stackTrace: stackTrace);
          return false;
        }
      }
    }
    
    return false;
  }

  /// Send welcome email (optional, for new registrations)
  Future<bool> sendWelcomeEmail({
    required String toEmail,
    required String userName,
    required String locale,
  }) async {
    if (!_isInitialized) {
      _logger.w('⚠️ EmailService not initialized');
      return false;
    }
    
    if (!_isTestMode && !_checkRateLimit()) {
      return false;
    }

    final subject = _getWelcomeSubject(locale);
    final htmlBody = _getWelcomeHtml(userName, locale);
    final textBody = _getWelcomeText(userName, locale);

    if (_isTestMode) {
      _logger.i('📧 [TEST MODE] Welcome Email:');
      _logger.i('   To: $toEmail');
      _logger.i('   Subject: $subject');
      return true;
    }

    return await _sendEmailWithRetry(
      toEmail: toEmail,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
      emailType: 'welcome',
    );
  }
  
  /// Send premium activation email
  Future<bool> sendPremiumActivationEmail({
    required String toEmail,
    required String userName,
    required String tier, // 'monthly', 'yearly', 'lifetime'
    required String locale,
    DateTime? expiryDate,
  }) async {
    if (!_isInitialized) {
      _logger.w('⚠️ EmailService not initialized');
      return false;
    }
    
    if (!_isTestMode && !_checkRateLimit()) {
      return false;
    }

    final subject = _getPremiumActivationSubject(locale);
    final htmlBody = _getPremiumActivationHtml(userName, tier, expiryDate, locale);
    final textBody = _getPremiumActivationText(userName, tier, expiryDate, locale);

    if (_isTestMode) {
      _logger.i('📧 [TEST MODE] Premium Activation Email:');
      _logger.i('   To: $toEmail');
      _logger.i('   Subject: $subject');
      _logger.i('   Tier: $tier');
      return true;
    }

    return await _sendEmailWithRetry(
      toEmail: toEmail,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
      emailType: 'premium_activation',
    );
  }
  
  /// Update API key securely
  Future<bool> updateApiKey(String apiKey) async {
    try {
      if (!await _validateApiKey(apiKey)) {
        _logger.e('❌ Invalid API key format');
        return false;
      }
      
      await _secureStorage.write(key: _secureStorageKey, value: apiKey);
      _apiKey = apiKey;
      _isTestMode = false;
      _logger.i('✅ API key updated successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to update API key: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Clear stored API key (for security)
  Future<void> clearApiKey() async {
    try {
      await _secureStorage.delete(key: _secureStorageKey);
      _apiKey = '';
      _isTestMode = true;
      _logger.i('✅ API key cleared from secure storage');
    } catch (e) {
      _logger.w('⚠️ Failed to clear API key: $e');
    }
  }
  
  /// Get email service status
  Map<String, dynamic> getStatus() {
    return {
      'isConfigured': isConfigured,
      'isTestMode': _isTestMode,
      'isInitialized': _isInitialized,
      'fromEmail': _fromEmail,
      'fromName': _fromName,
      'hasApiKey': _apiKey.isNotEmpty,
      'rateLimit': {
        'emailsLastMinute': _sentEmails.where((t) => 
          t.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))
        ).length,
        'emailsLastHour': _sentEmails.where((t) => 
          t.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
        ).length,
        'maxPerMinute': _maxEmailsPerMinute,
        'maxPerHour': _maxEmailsPerHour,
      },
    };
  }

  String _getPasswordResetSubject(String locale) {
    switch (locale) {
      case 'tr':
        return 'HemoAI - Şifre Sıfırlama';
      case 'es':
        return 'HemoAI - Restablecer Contraseña';
      case 'fr':
        return 'HemoAI - Réinitialisation du Mot de Passe';
      case 'de':
        return 'HemoAI - Passwort zurücksetzen';
      case 'ar':
        return 'HemoAI - إعادة تعيين كلمة المرور';
      default:
        return 'HemoAI - Password Reset';
    }
  }

  String _getPasswordResetHtml(String resetUrl, String locale) {
    final text = _getPasswordResetText(resetUrl, locale);
    final isRTL = locale == 'ar';
    
    return '''
<!DOCTYPE html>
<html dir="${isRTL ? 'rtl' : 'ltr'}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
      line-height: 1.6; 
      color: #333; 
      margin: 0; 
      padding: 0;
      background-color: #f5f5f5;
    }
    .container { 
      max-width: 600px; 
      margin: 0 auto; 
      padding: 40px 20px;
      background-color: #ffffff;
    }
    .header {
      text-align: center;
      padding: 30px 0;
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%);
      border-radius: 10px 10px 0 0;
      color: white;
    }
    .header h2 {
      margin: 0;
      font-size: 24px;
      font-weight: bold;
    }
    .content {
      padding: 30px 20px;
    }
    .button { 
      display: inline-block; 
      padding: 14px 32px; 
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%); 
      color: white !important; 
      text-decoration: none; 
      border-radius: 8px; 
      margin: 20px 0;
      font-weight: bold;
      text-align: center;
    }
    .button-container {
      text-align: center;
      margin: 30px 0;
    }
    .warning {
      background-color: #fff3cd;
      padding: 12px;
      border-radius: 6px;
      border-left: 4px solid #ffc107;
      margin: 20px 0;
      font-size: 14px;
    }
    .footer { 
      margin-top: 40px; 
      padding-top: 20px;
      border-top: 1px solid #e0e0e0;
      font-size: 12px; 
      color: #666; 
      text-align: center;
    }
    .url-fallback {
      word-break: break-all;
      font-size: 12px;
      color: #666;
      margin-top: 10px;
      padding: 10px;
      background-color: #f9f9f9;
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>${_getPasswordResetSubject(locale)}</h2>
    </div>
    <div class="content">
      <p style="font-size: 16px;">${text.split('\n\n').first}</p>
      <div class="button-container">
        <a href="$resetUrl" class="button">${locale == 'tr' ? 'Şifreyi Sıfırla' : locale == 'es' ? 'Restablecer Contraseña' : 'Reset Password'}</a>
      </div>
      <div class="warning">
        <strong>${locale == 'tr' ? '⚠️ Önemli:' : locale == 'es' ? '⚠️ Importante:' : '⚠️ Important:'}</strong><br>
        ${locale == 'tr' ? 'Bu bağlantı 24 saat boyunca geçerlidir. Güvenliğiniz için bağlantıyı başkalarıyla paylaşmayın.' : locale == 'es' ? 'Este enlace es válido durante 24 horas. Por seguridad, no comparta este enlace con nadie.' : 'This link is valid for 24 hours. For security, do not share this link with anyone.'}
      </div>
      <div class="url-fallback">
        ${locale == 'tr' ? 'Bağlantı çalışmıyorsa, bu URL\'yi tarayıcınıza kopyalayın:' : locale == 'es' ? 'Si el enlace no funciona, copie esta URL en su navegador:' : 'If the link doesn\'t work, copy this URL to your browser:'}<br>
        <span style="word-break: break-all;">$resetUrl</span>
      </div>
      <p style="margin-top: 20px; font-size: 14px; color: #666;">${text.split('\n\n').skip(1).join('\n\n').replaceAll('\n', '<br>')}</p>
    </div>
    <div class="footer">
      <p><strong>HemoAI</strong> - Smart Hemogram Analysis</p>
      <p>${locale == 'tr' ? 'Bu e-postayı siz istemediyseniz, lütfen görmezden gelin.' : locale == 'es' ? 'Si no solicitó este correo, puede ignorarlo.' : 'If you did not request this email, please ignore it.'}</p>
      <p style="margin-top: 10px;">support@hemoai.com</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _getPasswordResetText(String resetUrl, String locale) {
    switch (locale) {
      case 'tr':
        return '''Merhaba,

HemoAI hesabınız için şifre sıfırlama talebinde bulundunuz.

Şifrenizi sıfırlamak için aşağıdaki bağlantıya tıklayın:
$resetUrl

Bu bağlantı 24 saat boyunca geçerlidir.

Eğer bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz.

Saygılarımızla,
HemoAI Ekibi''';
      case 'es':
        return '''Hola,

Has solicitado restablecer la contraseña de tu cuenta HemoAI.

Haz clic en el siguiente enlace para restablecer tu contraseña:
$resetUrl

Este enlace es válido durante 24 horas.

Si no realizaste esta solicitud, puedes ignorar este correo.

Saludos,
Equipo HemoAI''';
      case 'fr':
        return '''Bonjour,

Vous avez demandé la réinitialisation du mot de passe de votre compte HemoAI.

Cliquez sur le lien suivant pour réinitialiser votre mot de passe:
$resetUrl

Ce lien est valide pendant 24 heures.

Si vous n'avez pas fait cette demande, vous pouvez ignorer cet e-mail.

Cordialement,
L'équipe HemoAI''';
      case 'de':
        return '''Hallo,

Sie haben die Zurücksetzung des Passworts für Ihr HemoAI-Konto angefordert.

Klicken Sie auf den folgenden Link, um Ihr Passwort zurückzusetzen:
$resetUrl

Dieser Link ist 24 Stunden lang gültig.

Wenn Sie diese Anforderung nicht gestellt haben, können Sie diese E-Mail ignorieren.

Mit freundlichen Grüßen,
Das HemoAI-Team''';
      case 'ar':
        return '''مرحباً،

لقد طلبت إعادة تعيين كلمة المرور لحسابك في HemoAI.

انقر على الرابط التالي لإعادة تعيين كلمة المرور:
$resetUrl

هذا الرابط صالح لمدة 24 ساعة.

إذا لم تطلب هذا، يمكنك تجاهل هذا البريد الإلكتروني.

تحياتنا،
فريق HemoAI''';
      default:
        return '''Hello,

You have requested to reset your password for your HemoAI account.

Click the following link to reset your password:
$resetUrl

This link is valid for 24 hours.

If you did not make this request, you can ignore this email.

Best regards,
HemoAI Team''';
    }
  }

  String _getWelcomeSubject(String locale) {
    switch (locale) {
      case 'tr':
        return 'HemoAI\'ye Hoş Geldiniz!';
      case 'es':
        return '¡Bienvenido a HemoAI!';
      case 'fr':
        return 'Bienvenue sur HemoAI!';
      case 'de':
        return 'Willkommen bei HemoAI!';
      case 'ar':
        return 'مرحباً بك في HemoAI!';
      default:
        return 'Welcome to HemoAI!';
    }
  }

  String _getWelcomeHtml(String userName, String locale) {
    final text = _getWelcomeText(userName, locale);
    final isRTL = locale == 'ar';
    
    return '''
<!DOCTYPE html>
<html dir="${isRTL ? 'rtl' : 'ltr'}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
      line-height: 1.6; 
      color: #333; 
      margin: 0; 
      padding: 0;
      background-color: #f5f5f5;
    }
    .container { 
      max-width: 600px; 
      margin: 0 auto; 
      padding: 40px 20px;
      background-color: #ffffff;
    }
    .header {
      text-align: center;
      padding: 30px 0;
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%);
      border-radius: 10px 10px 0 0;
      color: white;
    }
    .header h2 {
      margin: 0;
      font-size: 24px;
      font-weight: bold;
    }
    .content {
      padding: 30px 20px;
    }
    .features {
      background-color: #f9f9f9;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
    }
    .features ul {
      margin: 10px 0;
      padding-left: 20px;
    }
    .features li {
      margin: 8px 0;
    }
    .button {
      display: inline-block;
      padding: 14px 32px;
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%);
      color: white !important;
      text-decoration: none;
      border-radius: 8px;
      margin: 20px 0;
      font-weight: bold;
      text-align: center;
    }
    .button-container {
      text-align: center;
      margin: 30px 0;
    }
    .footer { 
      margin-top: 40px; 
      padding-top: 20px;
      border-top: 1px solid #e0e0e0;
      font-size: 12px; 
      color: #666; 
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>${_getWelcomeSubject(locale)}</h2>
    </div>
    <div class="content">
      <p style="font-size: 16px;">${text.split('\n\n').first.replaceAll(userName, '<strong>$userName</strong>')}</p>
      <div class="features">
        <h3 style="margin-top: 0;">${locale == 'tr' ? 'Başlamak için:' : locale == 'es' ? 'Para comenzar:' : 'To get started:'}</h3>
        <ul>
          <li>${locale == 'tr' ? 'Uygulamayı açın' : locale == 'es' ? 'Abre la aplicación' : 'Open the app'}</li>
          <li>${locale == 'tr' ? 'İlk hemogram değerlerinizi girin' : locale == 'es' ? 'Ingresa tus primeros valores de hemograma' : 'Enter your first hemogram values'}</li>
          <li>${locale == 'tr' ? 'AI analizi ve önerileri görüntüleyin' : locale == 'es' ? 'Ver análisis de IA y recomendaciones' : 'View AI analysis and recommendations'}</li>
        </ul>
      </div>
      <div class="button-container">
        <a href="https://hemoai.com" class="button">${locale == 'tr' ? 'HemoAI\'yi Aç' : locale == 'es' ? 'Abrir HemoAI' : 'Open HemoAI'}</a>
      </div>
      <p style="margin-top: 20px;">${text.split('\n\n').skip(1).join('\n\n').replaceAll('\n', '<br>')}</p>
    </div>
    <div class="footer">
      <p><strong>HemoAI</strong> - Smart Hemogram Analysis</p>
      <p>support@hemoai.com</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _getWelcomeText(String userName, String locale) {
    switch (locale) {
      case 'tr':
        return '''Merhaba $userName,

HemoAI ailesine hoş geldiniz! Akıllı hemogram analizi ve sağlık takip özelliklerimizle sağlığınızı optimize edebilirsiniz.

Başlamak için uygulamayı açın ve ilk hemogram değerlerinizi girin.

Başarılar dileriz!
HemoAI Ekibi''';
      case 'es':
        return '''Hola $userName,

¡Bienvenido a HemoAI! Ahora puedes optimizar tu salud con nuestro análisis inteligente de hemograma y funciones de seguimiento de salud.

Para comenzar, abre la aplicación e ingresa tus primeros valores de hemograma.

¡Buena suerte!
Equipo HemoAI''';
      case 'fr':
        return '''Bonjour $userName,

Bienvenue sur HemoAI! Vous pouvez maintenant optimiser votre santé avec notre analyse intelligente d'hémogramme et nos fonctionnalités de suivi de santé.

Pour commencer, ouvrez l'application et entrez vos premières valeurs d'hémogramme.

Bonne chance!
L'équipe HemoAI''';
      case 'de':
        return '''Hallo $userName,

Willkommen bei HemoAI! Sie können jetzt Ihre Gesundheit mit unserer intelligenten Hämogramm-Analyse und Gesundheits-Tracking-Funktionen optimieren.

Um zu beginnen, öffnen Sie die App und geben Sie Ihre ersten Hämogramm-Werte ein.

Viel Glück!
Das HemoAI-Team''';
      case 'ar':
        return '''مرحباً $userName,

مرحباً بك في HemoAI! يمكنك الآن تحسين صحتك مع تحليل تعداد الدم الذكي ووظائف تتبع الصحة لدينا.

للبدء، افتح التطبيق وأدخل أول قيم تعداد الدم الخاصة بك.

حظاً سعيداً!
فريق HemoAI''';
      default:
        return '''Hello $userName,

Welcome to HemoAI! You can now optimize your health with our smart hemogram analysis and health tracking features.

To get started, open the app and enter your first hemogram values.

Good luck!
HemoAI Team''';
    }
  }
  
  String _getPremiumActivationSubject(String locale) {
    switch (locale) {
      case 'tr':
        return 'HemoAI Premium Aktif! 🎉';
      case 'es':
        return '¡HemoAI Premium Activado! 🎉';
      case 'fr':
        return 'HemoAI Premium Activé! 🎉';
      case 'de':
        return 'HemoAI Premium Aktiviert! 🎉';
      case 'ar':
        return 'HemoAI Premium مفعّل! 🎉';
      default:
        return 'HemoAI Premium Activated! 🎉';
    }
  }
  
  String _getPremiumActivationHtml(String userName, String tier, DateTime? expiryDate, String locale) {
    final text = _getPremiumActivationText(userName, tier, expiryDate, locale);
    final tierName = _getTierName(tier, locale);
    final expiryText = expiryDate != null 
        ? _getExpiryText(expiryDate, locale)
        : '';
    final isRTL = locale == 'ar';
    
    return '''
<!DOCTYPE html>
<html dir="${isRTL ? 'rtl' : 'ltr'}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
      line-height: 1.6; 
      color: #333; 
      margin: 0; 
      padding: 0;
      background-color: #f5f5f5;
    }
    .container { 
      max-width: 600px; 
      margin: 0 auto; 
      padding: 40px 20px;
      background-color: #ffffff;
    }
    .header {
      text-align: center;
      padding: 30px 0;
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%);
      border-radius: 10px 10px 0 0;
      color: white;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: bold;
    }
    .content {
      padding: 30px 20px;
    }
    .badge {
      display: inline-block;
      padding: 8px 16px;
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%);
      color: white;
      border-radius: 20px;
      font-weight: bold;
      font-size: 14px;
      margin: 10px 0;
    }
    .button {
      display: inline-block;
      padding: 14px 32px;
      background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%);
      color: white !important;
      text-decoration: none;
      border-radius: 8px;
      margin: 20px 0;
      font-weight: bold;
      text-align: center;
    }
    .features {
      background-color: #f9f9f9;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
    }
    .features ul {
      margin: 10px 0;
      padding-left: 20px;
    }
    .features li {
      margin: 8px 0;
    }
    .footer { 
      margin-top: 40px; 
      padding-top: 20px;
      border-top: 1px solid #e0e0e0;
      font-size: 12px; 
      color: #666; 
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎉 ${locale == 'tr' ? 'Premium Aktif!' : locale == 'es' ? '¡Premium Activado!' : 'Premium Activated!'}</h1>
    </div>
    <div class="content">
      <p style="font-size: 16px; font-weight: 600;">${text.split('\n\n')[0].replaceAll(userName, '<strong>$userName</strong>')}</p>
      <div style="text-align: center;">
        <span class="badge">$tierName</span>
      </div>
      ${expiryText.isNotEmpty ? '<p style="background-color: #fff3cd; padding: 12px; border-radius: 6px; border-left: 4px solid #ffc107;"><strong>${locale == 'tr' ? 'Son Kullanma:' : 'Expires:'}</strong> $expiryText</p>' : ''}
      <p>${text.split('\n\n').skip(1).join('\n\n').replaceAll('\n', '<br>')}</p>
      <div style="text-align: center;">
        <a href="https://hemoai.com/premium" class="button">${locale == 'tr' ? 'Premium Özellikleri Gör' : locale == 'es' ? 'Ver Características Premium' : 'View Premium Features'}</a>
      </div>
    </div>
    <div class="footer">
      <p><strong>HemoAI</strong> - Smart Hemogram Analysis</p>
      <p>${locale == 'tr' ? 'Sorularınız için: support@hemoai.com' : 'Questions? support@hemoai.com'}</p>
    </div>
  </div>
</body>
</html>
''';
  }
  
  String _getPremiumActivationText(String userName, String tier, DateTime? expiryDate, String locale) {
    final tierName = _getTierName(tier, locale);
    final expiryText = expiryDate != null ? _getExpiryText(expiryDate, locale) : '';
    
    switch (locale) {
      case 'tr':
        return '''Merhaba $userName,

HemoAI Premium aboneliğiniz aktif edildi! 🎉

Abonelik Tipi: $tierName
${expiryDate != null ? 'Son Kullanma: $expiryText' : ''}

Artık tüm premium özelliklere erişebilirsiniz:
• Gelişmiş AI analizi ve risk skorlaması
• Kişiselleştirilmiş diyet önerileri
• Sınırsız test takibi
• Aile paneli özellikleri
• Öncelikli destek

Uygulamayı açarak premium özelliklerinizi kullanmaya başlayabilirsiniz.

Teşekkürler!
HemoAI Ekibi''';
      case 'es':
        return '''Hola $userName,

¡Tu suscripción a HemoAI Premium ha sido activada! 🎉

Tipo de Suscripción: $tierName
${expiryDate != null ? 'Vence: $expiryText' : ''}

Ahora tienes acceso a todas las funciones premium:
• Análisis de IA avanzado y puntuación de riesgos
• Recomendaciones de dieta personalizadas
• Seguimiento ilimitado de pruebas
• Funciones del panel familiar
• Soporte prioritario

Puedes comenzar a usar tus funciones premium abriendo la aplicación.

¡Gracias!
Equipo HemoAI''';
      case 'fr':
        return '''Bonjour $userName,

Votre abonnement HemoAI Premium a été activé! 🎉

Type d'abonnement: $tierName
${expiryDate != null ? 'Expire: $expiryText' : ''}

Vous avez maintenant accès à toutes les fonctionnalités premium:
• Analyse IA avancée et notation des risques
• Recommandations de régime personnalisées
• Suivi illimité des tests
• Fonctionnalités du panneau familial
• Support prioritaire

Vous pouvez commencer à utiliser vos fonctionnalités premium en ouvrant l'application.

Merci!
L'équipe HemoAI''';
      case 'de':
        return '''Hallo $userName,

Ihr HemoAI Premium-Abonnement wurde aktiviert! 🎉

Abonnementstyp: $tierName
${expiryDate != null ? 'Läuft ab: $expiryText' : ''}

Sie haben jetzt Zugang zu allen Premium-Funktionen:
• Erweiterte KI-Analyse und Risikobewertung
• Personalisierte Ernährungsempfehlungen
• Unbegrenzte Testverfolgung
• Familienpanel-Funktionen
• Prioritätssupport

Sie können beginnen, Ihre Premium-Funktionen zu nutzen, indem Sie die App öffnen.

Danke!
Das HemoAI-Team''';
      case 'ar':
        return '''مرحباً $userName,

تم تفعيل اشتراكك في HemoAI Premium! 🎉

نوع الاشتراك: $tierName
${expiryDate != null ? 'ينتهي: $expiryText' : ''}

لديك الآن إمكانية الوصول إلى جميع الميزات المميزة:
• تحليل ذكي متقدم وتقييم المخاطر
• توصيات غذائية مخصصة
• تتبع غير محدود للاختبارات
• ميزات لوحة العائلة
• دعم ذو أولوية

يمكنك البدء في استخدام ميزاتك المميزة عن طريق فتح التطبيق.

شكراً!
فريق HemoAI''';
      default:
        return '''Hello $userName,

Your HemoAI Premium subscription has been activated! 🎉

Subscription Type: $tierName
${expiryDate != null ? 'Expires: $expiryText' : ''}

You now have access to all premium features:
• Advanced AI analysis and risk scoring
• Personalized diet recommendations
• Unlimited test tracking
• Family panel features
• Priority support

You can start using your premium features by opening the app.

Thank you!
HemoAI Team''';
    }
  }
  
  String _getTierName(String tier, String locale) {
    switch (tier.toLowerCase()) {
      case 'monthly':
        return locale == 'tr' ? 'Aylık' : locale == 'es' ? 'Mensual' : locale == 'fr' ? 'Mensuel' : locale == 'de' ? 'Monatlich' : locale == 'ar' ? 'شهري' : 'Monthly';
      case 'yearly':
        return locale == 'tr' ? 'Yıllık' : locale == 'es' ? 'Anual' : locale == 'fr' ? 'Annuel' : locale == 'de' ? 'Jährlich' : locale == 'ar' ? 'سنوي' : 'Yearly';
      case 'lifetime':
        return locale == 'tr' ? 'Yaşam Boyu' : locale == 'es' ? 'De por Vida' : locale == 'fr' ? 'À vie' : locale == 'de' ? 'Lebenslang' : locale == 'ar' ? 'مدى الحياة' : 'Lifetime';
      default:
        return tier;
    }
  }
  
  String _getExpiryText(DateTime expiryDate, String locale) {
    final formatted = expiryDate.toIso8601String().substring(0, 10);
    if (locale == 'tr') {
      // DD.MM.YYYY format
      final parts = formatted.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    } else if (locale == 'es' || locale == 'fr' || locale == 'de') {
      // DD/MM/YYYY format
      final parts = formatted.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } else {
      // YYYY-MM-DD format (default)
      return formatted;
    }
  }
}

