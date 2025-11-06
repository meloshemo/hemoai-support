import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hemoai/services/theme_service.dart';
import 'package:hemoai/services/notification_service.dart';
import 'package:hemoai/services/push_notification_service.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:hemoai/services/analytics_service.dart';
import 'package:hemoai/services/daily_advice_service.dart';
import 'package:hemoai/services/water_service.dart';
import 'package:hemoai/main.dart';
// Repositories (SSoT)
import 'package:hemoai/repositories/user_repository.dart';
import 'package:hemoai/repositories/hemogram_repository.dart';
import 'package:hemoai/repositories/reminder_repository.dart';
import 'package:hemoai/repositories/notification_repository.dart';
import 'package:hemoai/repositories/medication_repository.dart';
import 'package:hemoai/repositories/water_repository.dart';

void main() {
  setUpAll(() {
    // Initialize database factory for desktop platforms in tests
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

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
          ChangeNotifierProvider(create: (_) => DailyAdviceService()..initialize()),
          ChangeNotifierProvider(create: (_) => WaterService()..initialize()),
          // Repository providers (match main.dart)
          Provider<UserRepository>(create: (_) => UserRepository()),
          Provider<HemogramRepository>(create: (_) => HemogramRepository()),
          Provider<ReminderRepository>(create: (_) => ReminderRepository()),
          Provider<NotificationRepository>(create: (_) => NotificationRepository()),
          Provider<MedicationRepository>(create: (_) => MedicationRepository()),
          Provider<WaterRepository>(create: (_) => WaterRepository()),
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
