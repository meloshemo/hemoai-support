/// Simple environment helper. Use --dart-define=APP_ENV=dev|staging|prod
class Env {
  static const String value = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  static bool get isProd => value.toLowerCase() == 'prod';
  static bool get isDev => value.toLowerCase() == 'dev';
  static bool get isStaging => value.toLowerCase() == 'staging';
  static const String webVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY', defaultValue: '');
}
