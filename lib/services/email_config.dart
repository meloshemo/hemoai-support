/// Email Service Configuration
/// 
/// For production:
/// 1. Sign up for SendGrid: https://sendgrid.com
/// 2. Create an API Key with "Mail Send" permissions
/// 3. Update the configuration below or use environment variables
/// 
/// Security Note: Never commit API keys to version control.
/// Use environment variables or secure configuration management.
library;

class EmailConfig {
  // Configure via --dart-define at build/run time to avoid hardcoding secrets
  // Example:
  // flutter run --dart-define=SENDGRID_API_KEY=SG.xxx...
  
  /// SendGrid API Key
  static const String sendGridApiKey = String.fromEnvironment(
    'SENDGRID_API_KEY',
    defaultValue: '',
  );
  
  /// From Email Address
  static const String fromEmail = String.fromEnvironment(
    'SENDGRID_FROM_EMAIL',
    defaultValue: 'noreply@hemoai.com',
  );
  
  /// From Name
  static const String fromName = String.fromEnvironment(
    'SENDGRID_FROM_NAME',
    defaultValue: 'HemoAI',
  );
  
  /// Enable test mode if API key is not configured
  static bool get testMode => sendGridApiKey.isEmpty;
  
  /// Check if email service is configured
  static bool get isConfigured => sendGridApiKey.isNotEmpty;
  
  /// Get configuration status message
  static String get status {
    if (isConfigured) {
      return 'Email service configured';
    }
    return 'Email service in test mode (configure SendGrid for production)';
  }
}

