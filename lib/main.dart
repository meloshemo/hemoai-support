import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/personal_info_screen.dart';
import 'screens/hemogram_entry_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/diet_program_screen.dart';
import 'screens/family_panel_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/alternative_medicine_screen.dart';
import 'screens/test_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_reminder_screen.dart';
import 'screens/reminder_list_screen.dart';
import 'screens/enhanced_notification_screen.dart';
import 'screens/export_options_screen.dart';
import 'screens/language_settings_screen.dart';
import 'screens/advanced_analytics_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: avoid_print
  print('[BOOT] Widgets binding initialized');
  // Initialize FFI database for desktop platforms (Windows, Linux, macOS)
  // Guard with kIsWeb to avoid evaluating Platform.* on Web (would throw UnsupportedError)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // ignore: avoid_print
    print('[BOOT] Initializing sqflite_common_ffi for desktop');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  final notificationService = NotificationService();
  final pushNotificationService = PushNotificationService();
  final localizationService = LocalizationService();
  
  // ignore: avoid_print
  print('[BOOT] Initializing NotificationService');
  notificationService.initialize();
  // ignore: avoid_print
  print('[BOOT] Initializing PushNotificationService');
  await pushNotificationService.initialize();
  // ignore: avoid_print
  print('[BOOT] Initializing LocalizationService');
  await localizationService.initialize();
  // ignore: avoid_print
  print('[BOOT] Services initialized, starting app');
  
  // Surface errors visibly (avoid silent blank screen on Web)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Also print to console
    // ignore: avoid_print
    print('FlutterError: \\n${details.exceptionAsString()}\\n${details.stack}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(details.toString()),
        ),
      ),
    );
  };

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeService()),
          ChangeNotifierProvider.value(value: notificationService),
          ChangeNotifierProvider.value(value: pushNotificationService),
          ChangeNotifierProvider.value(value: localizationService),
        ],
        child: HemoAIApp(),
      ),
    );
  }, (error, stack) {
    // ignore: avoid_print
    print('Uncaught zone error: $error');
    // ignore: avoid_print
    print(stack);
  });
}

class HemoAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('[BOOT] HemoAIApp build()');
    return Consumer2<ThemeService, LocalizationService>(
      builder: (context, themeService, localizationService, child) {
        return AnimatedBuilder(
          animation: themeService,
          builder: (context, child) {
            // ignore: avoid_print
            print('[BOOT] Building MaterialApp with locale: ${localizationService.currentLocale.languageCode}, dark: ${themeService.isDarkMode}');
            return MaterialApp(
              title: 'HEMOAI',
              theme: ThemeService.lightTheme,
              darkTheme: ThemeService.darkTheme,
              themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              themeAnimationDuration: const Duration(milliseconds: 150), // Ultra hızlı geçiş
              locale: localizationService.currentLocale,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/guest': (context) => GuestScreen(),
        '/personal_info': (context) => PersonalInfoScreen(),
        '/hemogram_entry': (context) => HemogramEntryScreen(),
        '/analysis': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, double>?;
          return AnalysisScreen(hemogramValues: args ?? const {});
        },
        '/diet_program': (context) => DietProgramScreen(),
        '/family_panel': (context) => FamilyPanelScreen(),
        '/notifications': (context) => EnhancedNotificationScreen(),
        '/alternative_medicine': (context) => AlternativeMedicineScreen(),
        '/test_login': (context) => TestLoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/add_reminder': (context) => AddReminderScreen(),
        '/reminders': (context) => ReminderListScreen(),
        '/export_options': (context) => const ExportOptionsScreen(),
        '/language_settings': (context) => const LanguageSettingsScreen(),
        '/advanced_analytics': (context) => const AdvancedAnalyticsScreen(),
      },
      supportedLocales: localizationService.supportedLocales,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
            );
          },
        );
      },
    );
  }
}
