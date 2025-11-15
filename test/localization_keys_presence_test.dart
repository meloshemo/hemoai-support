import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/localization_service.dart';

void main() {
  test('Critical localization keys present for all supported languages', () async {
    final loc = LocalizationService();
    await loc.initialize();

    final keysToCheck = [
      'welcome',
      'login',
      'support_center_title',
      'medical_consult_prompt',
      'medical_emergency_cta',
      'please_wait_message',
    ];

    for (final key in keysToCheck) {
      for (final locale in loc.supportedLocales) {
        loc.changeLanguage(locale.languageCode);
        final value = loc.getString(key, defaultValue: '');
        expect(value.isNotEmpty, isTrue,
            reason: 'Missing translation for key "$key" in ${locale.languageCode}');
      }
    }
  });
}
