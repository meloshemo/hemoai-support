# HemoAI — AI coding agent guide (OS4)

Purpose: Flutter app for hemogram tracking, AI-assisted analysis, reminders, and family features. This reflects branch `os4-dev` (tag `v4.0.0`). Keep guidance concrete and codebase-specific.

Architecture
- State: Provider + ChangeNotifier across services in `lib/services/*`. Always wire via `MultiProvider` (see `lib/main.dart`). Primary notifiers: `ThemeService`, `LocalizationService`, `NotificationService` (in-app), `PushNotificationService` (system-like), `AnalyticsService`, `WellnessService`, `SyncSchedulerService`, `DailyAdviceService`, `WaterService`, `PremiumService`, `ChallengeService`, `SocialChallengeService`, `ScreenshotOverlayService`, `MessagingService`, `FirestoreSyncService`.
- SSoT Repositories: `lib/repositories/*` (User, Hemogram, Reminder, Notification, Medication, Water) are provided as simple `Provider<T>`.
- App shell (`lib/main.dart`): sets localization delegates, routes, and desktop DB FFI (`sqflite_common_ffi`) guarded by `kIsWeb`. Crash reporting via `FirebaseCrashlytics` on non-web.
- Routing: Named routes on `MaterialApp.routes` with `onGenerateRoute` for args. Common names: `/`, `/dashboard`, `/login`, `/analysis`, `/alternative_medicine`, `/notifications`, `/diet_program`, `/personal_info`, `/language_settings`, `/hemogram_entry`, `/export_options`, `/family_panel`, `/reminders`, `/add_reminder`, `/data_import`, `/settings`, `/performance`, `/notification_debug`, `/stats`, `/about`, `/support`, `/medical_consent`.
- Persistence: Always use `DatabaseHelper.instance`.
  - Web: transparently proxies to `WebDatabaseHelper` (SharedPreferences JSON).
  - Mobile/Desktop: `sqflite`; desktop uses FFI initialized in `main.dart`.
  - Hemogram rule: one active hemogram per user; inserts auto-archive older rows (`status: active|archived`, `archived_at`). See `DatabaseHelper.insertHemogramTest` and `getHemogramTests`.
- Notifications: two layers that work together.
  - `NotificationService`: in-app reminders, daily water/advice scheduling, and DB-driven medication reminders. Manages repeat via enum `RepeatType`.
  - `PushNotificationService`: schedules/simulates OS notifications; auto-reschedules using `data['repeat']` and requires `data['hour']`/`['minute']` for reliable repeats. Maps to reminders with `data['reminder_id']` and keeps schedule<->reminder indices.
- Localization: Centralized in `LocalizationService`; text direction, current locale, and very large key map. Never hardcode user-facing strings.

Conventions
- i18n usage: `LocalizationService().getString('key')` or `getStringWithParams('key', {...})`. Multi-line lists are newline-delimited; `loc.getString('diet_breakfast_iron_list').split('\n')`.
- Widgets: Avoid `const` on any widget containing localized `Text` to prevent web compile issues.
- Platform: Guard any `Platform.*` or platform checks with `kIsWeb`; keep differences behind `DatabaseHelper`/web helpers.
- Routing params: `/analysis` expects a `Map<String,double>` or a map with `values` and optional `testDate` (string/DateTime). Follow `onGenerateRoute` in `main.dart`.

Developer workflows
- Analyze/lints: VS Code task "Flutter clean + get + analyze (OS4)" (runs clean; pub get; analyze).
- Run: Web/Edge via task "Run OS4 after cleanup (Edge)"; or desktop `-d windows`. Target is `lib/main.dart`.
- Tests: `test/app_smoke_test.dart` mirrors `main.dart` providers. If you add or reorder providers, mirror here to keep the smoke test green.
- Localization validator: `dart run tool/validate_localization.dart` flags Turkish literals and missing keys before commit (see `docs/LOCALIZATION_CHANGELOG.md`).
- Android setup: `android_setup.bat` accepts licenses and checks devices.

Integration tips (do this here)
- Database: Always go through `DatabaseHelper.instance`; on web it returns `WebDatabaseHelper` transparently. Don’t mix direct `SharedPreferences` or raw `sqflite` calls in features.
- Scheduling notifications: use `PushNotificationService.scheduleNotification(...)` and pass in `data`:
  - `repeat: 'none'|'daily'|'weekly'|'monthly'|'daily_motivation'`
  - `hour`, `minute` for repeat reliability
  - `reminder_id` to enable cancel/reschedule mapping
- Built-ins: `scheduleDailyMotivation(hour, minute)`, `scheduleDailyDietReminder(hour, minute)`, `scheduleWeeklyDietReminders(...)` are provided. In-app templates exist on `NotificationService` (e.g., `createMedicationReminder`).

Examples
- Fetch a string: `Provider.of<LocalizationService>(context, listen: false).getString('app_name')`.
- Render a list: `for (final line in loc.getString('diet_snack_iron_list').split('\n')) ...[Text(line)]`.
- Insert hemogram: `await DatabaseHelper.instance.insertHemogramTest({'user_id': id, 'test_date': '2025-10-10', 'hemoglobin': 13.5}); // auto-archives previous active`.

Key places
- `lib/main.dart` (wiring/routes/FFI), `lib/services/*` (state/services), `lib/repositories/*` (SSoT), `lib/screens/*` (features), `lib/utils/responsive_helper.dart`, `tool/validate_localization.dart`.

When in doubt
- Add localization keys instead of literals; use `DatabaseHelper` for storage; keep platform differences hidden behind existing helpers. Keep route names and providers consistent with `main.dart`.
