import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/services/localization_service.dart';

void main() {
  // Ensure Flutter bindings and mock SharedPreferences are ready
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationService Tests', () {
    late LocalizationService localizationService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localizationService = LocalizationService();
    });

    test('should create singleton instance', () {
      final instance1 = LocalizationService();
      final instance2 = LocalizationService();
      expect(instance1, equals(instance2));
    });

    group('Language Management', () {
      test('should default to English language', () {
        expect(localizationService.currentLanguageCode, equals('en'));
      });

      test('should change language successfully', () async {
        await localizationService.changeLanguage('en');
        expect(localizationService.currentLanguageCode, equals('en'));
        
        await localizationService.changeLanguage('tr');
        expect(localizationService.currentLanguageCode, equals('tr'));
      });

      test('should support all expected languages', () async {
        final supportedLanguages = ['tr', 'en', 'es', 'fr', 'de', 'ar'];
        
        for (final lang in supportedLanguages) {
          await localizationService.changeLanguage(lang);
          expect(localizationService.currentLanguageCode, equals(lang));
        }
      });
    });

    group('String Translation', () {
      test('should return translated strings for basic keys', () async {
        await localizationService.changeLanguage('en');
        
        final appName = localizationService.getString('app_name');
        expect(appName, equals('HemoAI'));
        
        final welcome = localizationService.getString('welcome');
        expect(welcome, isNotEmpty);
        expect(welcome, isA<String>());
      });

      test('should return Turkish translations', () async {
        await localizationService.changeLanguage('tr');
        
        final welcome = localizationService.getString('welcome');
        expect(welcome, equals('Hoş Geldiniz'));
        
        final settings = localizationService.getString('settings');
        expect(settings, equals('Ayarlar'));
      });

      test('should handle missing keys gracefully', () async {
        await localizationService.changeLanguage('en');
        
        final nonExistent = localizationService.getString('non_existent_key');
        expect(nonExistent, equals('non_existent_key'));
      });
    });

    group('Parameterized Translations', () {
      test('should replace parameters in strings', () async {
        await localizationService.changeLanguage('en');
        
        final paramString = localizationService.getStringWithParams(
          'suitable_for_age', 
          {'age_group': 'Adult'}
        );
        expect(paramString, contains('Adult'));
      });

      test('should handle multiple parameters', () async {
        await localizationService.changeLanguage('en');
        
        final multiParam = localizationService.getStringWithParams(
          'weekly_reminders_scheduled',
          {'count': '5'}
        );
        expect(multiParam, contains('5'));
      });
    });

    group('Utility Methods', () {
      test('should provide language name', () async {
        await localizationService.changeLanguage('tr');
        expect(localizationService.currentLanguageName, equals('Türkçe'));
        
        await localizationService.changeLanguage('en');
        expect(localizationService.currentLanguageName, equals('English'));
      });

      test('should provide language flags', () async {
        await localizationService.changeLanguage('tr');
        expect(localizationService.currentLanguageFlag, equals('🇹🇷'));
        
        await localizationService.changeLanguage('en');
        expect(localizationService.currentLanguageFlag, equals('🇺🇸'));
      });
    });

    group('Specific Key Tests', () {
      test('should have consistent key translations', () async {
        await localizationService.changeLanguage('en');
        
        // Test critical app keys
        expect(localizationService.getString('settings'), equals('Settings'));
        expect(localizationService.getString('login'), equals('Login'));
        expect(localizationService.getString('analysis'), equals('Analysis'));
      });

      test('should maintain Turkish translations', () async {
        await localizationService.changeLanguage('tr');
        
        expect(localizationService.getString('settings'), equals('Ayarlar'));
        expect(localizationService.getString('login'), equals('Giriş Yap'));
        expect(localizationService.getString('analysis'), equals('Analiz'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty parameter maps', () async {
        await localizationService.changeLanguage('en');
        
        final result = localizationService.getStringWithParams('app_name', {});
        expect(result, equals('HemoAI'));
      });

      test('should maintain singleton after language changes', () async {
        final instance1 = LocalizationService();
        await localizationService.changeLanguage('tr');
        final instance2 = LocalizationService();
        
        expect(instance1, equals(instance2));
        expect(instance2.currentLanguageCode, equals('tr'));
      });
    });
  });
}