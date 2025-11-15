import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hemoai/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Language switch updates UI text and persists', (tester) async {
    final loc = LocalizationService();
    await loc.initialize();

    Widget buildApp() {
      return ChangeNotifierProvider<LocalizationService>.value(
        value: loc,
        child: Consumer<LocalizationService>(
          builder: (context, localization, _) {
            return MaterialApp(
              locale: localization.currentLocale,
              home: Scaffold(
                body: Center(
                  child: Text(localization.getString('welcome')),
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    // Default is English per service default
    expect(find.text('Welcome'), findsOneWidget);

    // Change to Turkish and ensure UI updates
    await loc.changeLanguage('tr');
    await tester.pump();

    expect(find.text('Hoş Geldiniz'), findsOneWidget);

    // Validate persistence keys were written
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), equals('tr'));
    expect(prefs.getString('selected_language'), equals('tr'));
  });
}
