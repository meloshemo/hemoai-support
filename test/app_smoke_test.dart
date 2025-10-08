import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hemoai/services/theme_service.dart';
import 'package:hemoai/services/notification_service.dart';
import 'package:hemoai/services/push_notification_service.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:hemoai/services/analytics_service.dart';
import 'package:hemoai/main.dart';

void main() {
  testWidgets('HemoAIApp builds without crashing', (WidgetTester tester) async {
    // Wrap HemoAIApp with the expected providers as in main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => NotificationService()..initialize()),
          ChangeNotifierProvider(create: (_) => PushNotificationService()..initialize()),
          ChangeNotifierProvider(create: (_) => LocalizationService()..initialize()),
          ChangeNotifierProvider(create: (_) => AnalyticsService()..initialize()),
        ],
        child: HemoAIApp(),
      ),
    );
    // Avoid indefinite settle due to async initializations; do a bounded pump loop
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Expect at least a MaterialApp to be present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
