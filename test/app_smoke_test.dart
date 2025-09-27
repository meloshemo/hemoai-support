import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hemoai/services/theme_service.dart';
import 'package:hemoai/services/notification_service.dart';
import 'package:hemoai/services/push_notification_service.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:hemoai/main.dart';

void main() {
  testWidgets('HemoAIApp builds without crashing', (WidgetTester tester) async {
    // Wrap HemoAIApp with the expected providers as in main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
          ChangeNotifierProvider(create: (_) => PushNotificationService()),
          ChangeNotifierProvider(create: (_) => LocalizationService()),
        ],
        child: HemoAIApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Expect at least a MaterialApp to be present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
