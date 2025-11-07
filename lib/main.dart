import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Legacy OS-3 services (ChangeNotifier-based)
import 'services/theme_service.dart';
import 'services/notification_service.dart' as inapp_notifications;
import 'services/push_notification_service.dart';
import 'services/localization_service.dart';
import 'services/analytics_service.dart';
import 'services/wellness_service.dart';
import 'services/sync_scheduler_service.dart';
import 'services/daily_advice_service.dart';
import 'services/water_service.dart';
import 'services/premium_service.dart';
import 'services/challenge_service.dart';
import 'services/social_challenge_service.dart';

// Legacy OS-3 screens and routing targets
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/alternative_medicine_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/diet_program_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/personal_info_screen_new.dart' as legacy_personal_info;
import 'screens/language_settings_screen.dart';
import 'screens/hemogram_entry_screen.dart';
import 'screens/export_options_screen_simple.dart' as export_simple;
import 'screens/family_panel_screen.dart';
import 'screens/family_member_detail_screen.dart';
import 'screens/reminder_list_screen.dart';
import 'screens/add_reminder_screen.dart';
import 'services/preferences_service.dart';
import 'services/email_service.dart';
import 'services/auto_backup_service.dart';
import 'screens/settings_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/performance_screen.dart';
import 'screens/notification_debug_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/about_screen.dart';
import 'screens/advanced_analytics_screen.dart';
import 'screens/all_quotes_screen.dart';
import 'screens/data_import_screen.dart';
import 'screens/challenges_screen.dart';
// Repositories (SSoT)
import 'repositories/user_repository.dart';
import 'repositories/hemogram_repository.dart';
import 'repositories/reminder_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/medication_repository.dart';
import 'repositories/water_repository.dart';

void main() async {
  // Ensure bindings are ready before any async/service work
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SQLite FFI on desktop (Windows/Linux/macOS)
  if (!kIsWeb) {
    final isDesktop = {
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    }.contains(defaultTargetPlatform);
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Best-effort security migration: move PII to secure storage on startup
  PreferencesService.getInstance().then((p) => p.ensurePiiSecured());
  
  // Initialize email service (automatically uses config or test mode)
  await EmailService().initialize(); // Will use EmailConfig or test mode
  
  // Initialize auto backup service
  await AutoBackupService().setEnabled(true); // Default: enabled

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => inapp_notifications.NotificationService()..initialize()),
        ChangeNotifierProvider(create: (_) => PushNotificationService()..initialize()),
        ChangeNotifierProvider(create: (_) => LocalizationService()..initialize()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()..initialize()),
        ChangeNotifierProvider(create: (_) => WellnessService()..initialize()),
        ChangeNotifierProvider(create: (_) => SyncSchedulerService()..initialize()),
        ChangeNotifierProvider(create: (_) => DailyAdviceService()..initialize()),
        ChangeNotifierProvider(create: (_) => WaterService()..initialize()),
        ChangeNotifierProvider(create: (_) => PremiumService()..initialize()),
        ChangeNotifierProvider(create: (_) => ChallengeService()..initialize()),
        ChangeNotifierProvider(create: (_) => SocialChallengeService()..initialize()),
        // Provide repositories as app-wide singletons via Provider (stateless, no ChangeNotifier)
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<HemogramRepository>(create: (_) => HemogramRepository()),
        Provider<ReminderRepository>(create: (_) => ReminderRepository()),
        Provider<NotificationRepository>(create: (_) => NotificationRepository()),
        Provider<MedicationRepository>(create: (_) => MedicationRepository()),
        Provider<WaterRepository>(create: (_) => WaterRepository()),
      ],
      child: const HemoAIApp(),
    ),
  );
}

class HemoAIApp extends StatelessWidget {
  const HemoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localization = Provider.of<LocalizationService>(context);

  return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HemoAI',

      // Theme
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Localization
      locale: localization.currentLocale,
      supportedLocales: localization.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const _AuthGate(),
        '/dashboard': (context) => DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/guest': (context) => const GuestScreen(),
        '/alternative_medicine': (context) => const AlternativeMedicineScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/diet_program': (context) => const DietProgramScreen(),
        '/personal_info': (context) => const legacy_personal_info.PersonalInfoScreen(),
        '/language_settings': (context) => const LanguageSettingsScreen(),
        '/hemogram_entry': (context) => HemogramEntryScreen(),
        '/export_options': (context) => const export_simple.ExportOptionsScreen(),
  '/advanced_analytics': (context) => const AdvancedAnalyticsScreen(),
        '/family_panel': (context) => const FamilyPanelScreen(),
        '/family_member_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final member = (args is Map<String, dynamic>) ? args : <String, dynamic>{};
          return FamilyMemberDetailScreen(member: member);
        },
        '/reminders': (context) => const ReminderListScreen(),
        '/add_reminder': (context) => const AddReminderScreen(),
    '/data_import': (context) => const DataImportScreen(),
        // Settings and tools
        '/settings': (context) => SettingsScreen(),
        '/premium': (context) => const PremiumScreen(),
        '/performance': (context) => PerformanceScreen(),
        '/notification_debug': (context) => NotificationDebugScreen(),
        '/stats': (context) => StatsScreen(),
        '/about': (context) => AboutScreen(),
        '/challenges': (context) => ChallengesScreen(),
        '/all_quotes': (context) => const AllQuotesScreen(),
      },

      // Handle routes needing arguments (e.g., /analysis with values)
      onGenerateRoute: (settings) {
        // Safety net: handle some named routes here too
        switch (settings.name) {
          case '/family_panel':
            return MaterialPageRoute(
              builder: (_) => const FamilyPanelScreen(),
              settings: settings,
            );
          case '/reminders':
            return MaterialPageRoute(
              builder: (_) => const ReminderListScreen(),
              settings: settings,
            );
          case '/add_reminder':
            return MaterialPageRoute(
              builder: (_) => const AddReminderScreen(),
              settings: settings,
            );
        }
        if (settings.name == '/analysis') {
          final args = settings.arguments;
          final values = (args is Map<String, double>) ? args : <String, double>{};
          return MaterialPageRoute(
            builder: (_) => AnalysisScreen(hemogramValues: values),
            settings: settings,
          );
        }
        return null;
      },

      // Fallback for any unknown routes to avoid crashes in release
      onUnknownRoute: (settings) {
        debugPrint('Unknown route requested: \'${settings.name}\'');
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(),
          settings: const RouteSettings(name: '/dashboard'),
        );
      },

      builder: (context, child) {
        // Ensure consistent text scaling and text direction per LocalizationService
        final media = MediaQuery.of(context);
        // Respect system text scaling, but clamp to a sensible range for layout stability
        final factor = media.textScaleFactor.clamp(0.9, 1.6);
        return Directionality(
          textDirection: localization.textDirection,
          child: MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(factor)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _navigated = false;
  

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await PreferencesService.getInstance();
      final logged = prefs.isUserLoggedIn();
      if (!mounted) return;
      setState(() {
        _loggedIn = logged;
        _loading = false;
      });
      // If user is neither logged in nor guest but onboarding is done, keep to login
      // If onboarding is needed, we'll route there in build
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedIn = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Redirect based on auth state
    if (!_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_navigated) return; // double guard
        final current = ModalRoute.of(context)?.settings.name;
        // If user already navigated to an inner page (e.g., /family_panel), don't override it
        const safeInnerRoutes = {
          '/family_panel',
          '/reminders',
          '/add_reminder',
          '/analysis',
          '/diet_program',
          '/alternative_medicine',
          '/personal_info',
          '/notifications',
          '/language_settings',
          '/hemogram_entry',
          '/export_options',
          '/data_import',
          // Newly added routes
          '/settings',
          '/performance',
          '/notification_debug',
          '/stats',
          '/about',
        };
        if (current != null && safeInnerRoutes.contains(current)) {
          _navigated = true;
          return;
        }
        final route = _loggedIn ? '/dashboard' : '/login';
        if (current != route) {
          _navigated = true;
          Navigator.of(context).pushReplacementNamed(route);
        }
      });
    }
    return const SizedBox.shrink();
  }
}
