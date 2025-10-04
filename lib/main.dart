import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Services
import 'services/localization_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/active_profile_service.dart';
import 'services/analytics_service.dart';
import 'services/auto_restore_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/personal_info_screen.dart';
import 'screens/hemogram_entry_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/diet_program_screen.dart';
// import 'screens/family_panel_screen.dart';
import 'screens/family_panel_screen_old.dart' as fam_old;
import 'screens/notification_screen.dart';
// Restored panels/routes
// import 'screens/dashboard_screen.dart';
import 'screens/dashboard_screen_backup.dart' as dash_old;
import 'screens/add_reminder_screen.dart';
import 'screens/reminder_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/language_settings_screen.dart';
import 'screens/alternative_medicine_screen.dart';
// import 'screens/export_options_screen.dart';
import 'screens/export_options_screen_backup.dart' as exp_old;
import 'screens/advanced_analytics_screen.dart';
import 'screens/data_import_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/performance_screen.dart';
import 'screens/ocr_reader_screen.dart';
import 'screens/ocr_review_screen.dart';
import 'screens/full_results_screen.dart';
import 'screens/enhanced_notification_screen.dart';
import 'screens/dev_auto_restore_screen.dart';
import 'screens/about_screen.dart';
import 'screens/notification_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop için sqflite FFI (Windows/macOS/Linux)
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // One-time desktop auto-restore from latest backup in Downloads
  await AutoRestoreService().runOnceAtStartup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final svc = LocalizationService();
          // Kaydedilmiş dili yükle
          svc.initialize();
          return svc;
        }),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => PushNotificationService()),
        ChangeNotifierProvider(create: (_) => ActiveProfileService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()..initialize()),
      ],
      child: const HemoAIApp(),
    ),
  );
}

class HemoAIApp extends StatelessWidget {
  const HemoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    final loc = Provider.of<LocalizationService>(context, listen: true);

    return MaterialApp(
      title: 'HEMOAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      // Respect user toggle instead of system brightness
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: loc.supportedLocales,
      locale: loc.currentLocale,
  // Always start from Dashboard for a reliable startup
  initialRoute: '/dashboard',
      routes: {
        // Auth
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/guest': (context) => const GuestScreen(),
        '/personal_info': (context) => const PersonalInfoScreen(),
        // Core dashboard and panels
  // Use the previous favorite Dashboard layout
  '/dashboard': (context) => const dash_old.DashboardScreen(),
        '/hemogram_entry': (context) => HemogramEntryScreen(),
        '/analysis': (context) => AnalysisScreen(),
        '/diet_program': (context) => const DietProgramScreen(),
  // Use the older Family Panel implementation
  '/family_panel': (context) => const fam_old.FamilyPanelScreen(),
        // Notifications: support both singular and plural route names
        '/notification': (context) => const NotificationScreen(),
        '/notifications': (context) => const NotificationScreen(),
        // Reminders
        '/add_reminder': (context) => const AddReminderScreen(),
        '/reminders': (context) => const ReminderListScreen(),
        // Settings and language
        '/settings': (context) => const SettingsScreen(),
        '/language_settings': (context) => const LanguageSettingsScreen(),
        // Alternative medicine and export options
        '/alternative_medicine': (context) => const AlternativeMedicineScreen(),
  // Use the previous Export Options screen design
  '/export_options': (context) => const exp_old.ExportOptionsScreen(),
        // Advanced/Tools
        '/advanced_analytics': (context) => const AdvancedAnalyticsScreen(),
        '/data_import': (context) => const DataImportScreen(),
        // Extra tools/panels
        '/stats': (context) => const StatsScreen(),
        '/performance': (context) => const PerformanceScreen(),
        '/ocr_reader': (context) => const OcrReaderScreen(),
        '/ocr_review': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          Map<String, String> extracted = const {};
          String sourcePath = '';
          void Function(Map<String, double>) onConfirm = (_) {};
          if (args is Map) {
            final map = Map<String, dynamic>.from(args);
            if (map['extractedValues'] is Map) {
              extracted = Map<String, String>.from(map['extractedValues'] as Map);
            }
            if (map['sourceImagePath'] is String) {
              sourcePath = map['sourceImagePath'] as String;
            }
            if (map['onConfirm'] is void Function(Map<String, double>)) {
              onConfirm = map['onConfirm'] as void Function(Map<String, double>);
            } else {
              onConfirm = (values) {
                Navigator.of(context).pop(values);
              };
            }
          }
          return OCRReviewScreen(
            extractedValues: extracted,
            sourceImagePath: sourcePath,
            onConfirm: onConfirm,
          );
        },
        '/full_results': (context) => const FullResultsScreen(),
        '/enhanced_notifications': (context) => const EnhancedNotificationScreen(),
        '/notification_debug': (context) => const NotificationDebugScreen(),
        '/about': (context) => const AboutScreen(),
        // Developer auto-restore route (temporary)
        '/dev_auto_restore': (context) => const DevAutoRestoreScreen(),
      },
    );
  }
}