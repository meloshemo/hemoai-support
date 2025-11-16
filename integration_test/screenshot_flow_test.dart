import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hemoai/main.dart' as app;
import 'package:hemoai/services/preferences_service.dart';

/// Drives core screens and captures store screenshots.
/// Run:
///   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_flow_test.dart -d <device>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  Future<void> take(String name) async {
    // Saves to integration_test/screenshots/ for Android/iOS
    await binding.takeScreenshot(name);
  }

  testWidgets('Store screenshots flow', (tester) async {
    // Launch app in test mode to avoid telemetry noise
    app.main(testMode: true);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Enable screenshot support on Android
    await binding.convertFlutterSurfaceToImage();

    // Ensure logged-in state for navigation
    await tester.runAsync(() async {
      final prefs = await PreferencesService.getInstance();
      await prefs.setUserInfo('Test User', 'test@example.com', '5551234567');
      await prefs.setPersonalInfo(30, 'male', 175, 70);
      await prefs.setOnboardingCompleted(true);
    });
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 1) Dashboard
    await take('01_dashboard');

    // 2) Hemogram Entry
    final hemogramIcon = find.byIcon(Icons.bloodtype);
    if (hemogramIcon.evaluate().isNotEmpty) {
      await tester.tap(hemogramIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('02_hemogram_entry');
    }

    // 3) Analysis
    try {
      final analysisBtn = find.textContaining(RegExp('Analiz|Analysis', caseSensitive: false));
      if (analysisBtn.evaluate().isNotEmpty) {
        await tester.tap(analysisBtn.first);
      } else {
        // Navigate via route
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.pushNamed('/analysis');
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('03_analysis');
    } catch (e) {
      debugPrint('Analysis navigation error: $e');
    }

    // 4) Notifications
    await tester.pageBack();
    await tester.pumpAndSettle();
    final notifIcon = find.byIcon(Icons.notifications);
    if (notifIcon.evaluate().isNotEmpty) {
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('04_notifications');
    }

    // 5) Reminders
    await tester.pageBack();
    await tester.pumpAndSettle();
    final reminderIcon = find.byIcon(Icons.alarm);
    if (reminderIcon.evaluate().isNotEmpty) {
      await tester.tap(reminderIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('05_reminders');
    }

    // 6) Settings
    await tester.pageBack();
    await tester.pumpAndSettle();
    final settingsIcon = find.byIcon(Icons.settings);
    if (settingsIcon.evaluate().isNotEmpty) {
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await take('06_settings');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
