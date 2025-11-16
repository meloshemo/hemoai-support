import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
import 'screens/enhanced_notification_screen.dart';
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
import 'screens/support_screen.dart';
import 'screens/onboarding/medical_consent_screen.dart';
// Repositories (SSoT)
import 'repositories/user_repository.dart';
import 'repositories/hemogram_repository.dart';
import 'repositories/reminder_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/medication_repository.dart';
import 'repositories/water_repository.dart';
import 'firebase/firebase_initializer.dart';
import 'services/screenshot_overlay_service.dart';
import 'services/firestore_sync_service.dart';
import 'services/messaging_service.dart';

void main({bool testMode = false}) {
  if (testMode) {
    _bootstrapApp(testMode: true).then((appWidget) {
      runApp(appWidget);
    });
    return;
  }

  runZonedGuarded(() async {
    final appWidget = await _bootstrapApp(testMode: false);
    runApp(appWidget);
  }, (error, stack) async {
    if (!kIsWeb) {
      try {
        await FirebaseCrashlytics.instance
            .recordError(error, stack, fatal: true);
      } catch (_) {
        debugPrint('Crashlytics recordError failed: $error');
      }
    }
  });
}

Future<Widget> _bootstrapApp({required bool testMode}) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await initializeFirebaseTelemetry(skipTelemetry: testMode);
  // Enable Firestore offline persistence early (ignore errors if Firestore not yet configured)
  try {
    // Only attempt if cloud_firestore is available; dynamic import guard not needed in Dart
    // FirestoreSyncService will perform further snapshot wiring.
    FirestoreSyncService.ensurePersistence();
  } catch (_) {}

  PreferencesService.getInstance().then((p) => p.ensurePiiSecured());

  await EmailService().initialize();
  final autoBackup = AutoBackupService();
  await autoBackup.setEnabled(true);
  // Silent auto-restore on startup
  await autoBackup.autoRestoreOnStartup();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeService()),
      ChangeNotifierProvider(
          create: (_) =>
              inapp_notifications.NotificationService()..initialize()),
      ChangeNotifierProvider(
          create: (_) => PushNotificationService()..initialize()),
      ChangeNotifierProvider(
          create: (_) => LocalizationService()..initialize()),
      ChangeNotifierProvider(create: (_) => AnalyticsService()..initialize()),
      ChangeNotifierProvider(create: (_) => WellnessService()..initialize()),
      ChangeNotifierProvider(
          create: (_) => SyncSchedulerService()..initialize()),
      ChangeNotifierProvider(create: (_) => DailyAdviceService()..initialize()),
      ChangeNotifierProvider(create: (_) => WaterService()..initialize()),
      ChangeNotifierProvider(create: (_) => PremiumService()..initialize()),
      ChangeNotifierProvider(create: (_) => ChallengeService()..initialize()),
      ChangeNotifierProvider(
          create: (_) => SocialChallengeService()..initialize()),
      ChangeNotifierProvider(create: (_) => ScreenshotOverlayService()),
      ChangeNotifierProvider(create: (_) => MessagingService()..initialize()),
      ChangeNotifierProvider(
          create: (_) => FirestoreSyncService()..initialize()),
      Provider<UserRepository>(create: (_) => UserRepository()),
      Provider<HemogramRepository>(create: (_) => HemogramRepository()),
      Provider<ReminderRepository>(create: (_) => ReminderRepository()),
      Provider<NotificationRepository>(create: (_) => NotificationRepository()),
      Provider<MedicationRepository>(create: (_) => MedicationRepository()),
      Provider<WaterRepository>(create: (_) => WaterRepository()),
    ],
    child: const HemoAIApp(),
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
        '/notifications': (context) => const EnhancedNotificationScreen(),
        '/diet_program': (context) => const DietProgramScreen(),
        '/personal_info': (context) =>
            const legacy_personal_info.PersonalInfoScreen(),
        '/language_settings': (context) => const LanguageSettingsScreen(),
        '/hemogram_entry': (context) => HemogramEntryScreen(),
        '/export_options': (context) =>
            const export_simple.ExportOptionsScreen(),
        '/advanced_analytics': (context) => const AdvancedAnalyticsScreen(),
        '/family_panel': (context) => const FamilyPanelScreen(),
        '/family_member_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final member =
              (args is Map<String, dynamic>) ? args : <String, dynamic>{};
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
        '/support': (context) => const SupportScreen(),
        '/medical_consent': (context) => const MedicalConsentScreen(),
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
          Map<String, double> values = {};
          DateTime? testDate;
          if (args is Map<String, double>) {
            values = Map<String, double>.from(args);
          } else if (args is Map<String, dynamic>) {
            final rawValues = args['values'];
            if (rawValues is Map) {
              final temp = <String, double>{};
              rawValues.forEach((key, value) {
                if (value is num) {
                  temp[key.toString()] = value.toDouble();
                } else if (value is String) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    temp[key.toString()] = parsed;
                  }
                }
              });
              values = temp;
            }
            final rawDate = args['testDate'];
            if (rawDate is DateTime) {
              testDate = rawDate;
            } else if (rawDate is String) {
              testDate = DateTime.tryParse(rawDate);
            }
          }
          return MaterialPageRoute(
            builder: (_) =>
                AnalysisScreen(hemogramValues: values, testDate: testDate),
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
        final clampedTextScaler =
            media.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.6);
        // Screenshot overlay: shown only when enabled via ScreenshotOverlayService (used in automated screenshots)
        final ss = Provider.of<ScreenshotOverlayService>(context);
        Widget composed = RepaintBoundary(
          // Wrap in RepaintBoundary for screenshot capture in integration tests
          child: Directionality(
            textDirection: localization.textDirection,
            child: MediaQuery(
            data: media.copyWith(textScaler: clampedTextScaler),
            child: child ?? const SizedBox.shrink(),
          ),
        );

        // Wrap the entire content in a RepaintBoundary to support high-fidelity captures
        composed = RepaintBoundary(
          key: Provider.of<ScreenshotOverlayService>(context, listen: false)
              .repaintBoundaryKey,
          child: composed,
        );

        if (ss.enabled) {
          composed = Stack(
            fit: StackFit.expand,
            children: [
              composed,
              // Top-centered overlay banner
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      localization.getString(ss.localizedTitleKey ?? 'app_name',
                          defaultValue: 'HemoAI'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return composed;
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
  bool _consentAccepted = false;
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
      final consent = prefs.isMedicalConsentAccepted();
      if (!mounted) return;
      setState(() {
        _loggedIn = logged;
        _consentAccepted = consent;
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
          '/support',
          '/medical_consent',
        };
        if (current != null && safeInnerRoutes.contains(current)) {
          _navigated = true;
          return;
        }
        String route;
        if (_loggedIn) {
          route = _consentAccepted ? '/dashboard' : '/medical_consent';
        } else {
          route = '/login';
        }
        if (current != route) {
          _navigated = true;
          Navigator.of(context).pushReplacementNamed(route);
        }
      });
    }
    return const SizedBox.shrink();
  }
}
