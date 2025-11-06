# HemoAI — AI coding agent guide (OS 4)

Purpose: Flutter app for hemogram tracking, AI-assisted analysis, reminders, and family features. These rules reflect the OS 4 baseline (tag `v4.0.0`, branch `os4-dev`).

Architecture
- State: Provider + ChangeNotifier. Core singletons in `lib/services/*`: `ThemeService`, `NotificationService`, `PushNotificationService`, `LocalizationService`, `ActiveProfileService`.
- App shell: `lib/main.dart` wires providers, named routes, localization delegates, and desktop DB FFI init. Guard any `Platform.*` with `kIsWeb`.
- Routing: Named routes in `MaterialApp.routes` (e.g., `/`, `/analysis`, `/alternative_medicine`, `/notifications`, `/export_options`).
- Persistence: Always use `DatabaseHelper.instance`.
  - Web: `WebDatabaseHelper` (SharedPreferences-backed JSON) transparently.
  - Desktop/Mobile: sqflite; desktop via `sqflite_common_ffi` initialized in `main.dart`.
- Notifications:
  - `NotificationService`: in-app reminders list + repeat logic.
  - `PushNotificationService`: schedules/simulates system notifications; auto-reschedules via `data['repeat']` and maps to reminders with `data['reminder_id']`.
- Localization: Centralized in `LocalizationService`; never hardcode user-facing text.

Conventions
- i18n: Use `LocalizationService().getString('key')` or `getStringWithParams('key', {...})`. Add TR/EN keys in `lib/services/localization_service.dart` before UI changes. Lists are newline-delimited; split with `.split('\n')`.
- Widgets: Avoid `const` on widgets whose `Text` is localized (causes web compile issues).
- Platform: Do not call `Platform.*` on web; use `kIsWeb` and keep differences behind helpers.
- UI/layout: Prefer `lib/utils/responsive_helper.dart` for grids/spacing.

Workflows
- Analyze/lints: Run the VS Code task "Flutter clean + get + analyze (OS4)" or run `flutter clean`, `flutter pub get`, then `flutter analyze`.
- Run (Web/Edge): VS Code task "Run OS4 after cleanup (Edge)" or `flutter run -d edge -t lib/main.dart`. Windows desktop: `flutter run -d windows`.
- Tests: `test/app_smoke_test.dart` expects the same provider set as `main.dart`. If you add providers, mirror them in tests.
- Localization check: `dart run tool/validate_localization.dart` flags Turkish literals and missing keys; run before commit. Changes are tracked in `docs/LOCALIZATION_CHANGELOG.md`.
- Android setup: `android_setup.bat` accepts SDK licenses and checks devices.

Integration tips
- Scheduling reminders: when calling `PushNotificationService.scheduleNotification(...)`, include in `data`: `repeat` ('none'|'daily'|'weekly'|'monthly'), `hour`, `minute`, `reminder_id` for auto-reschedule/cancellation mapping.
- Startup sync (see `main.dart`): load reminders (e.g., `WebDatabaseHelper.getReminders(userId)`) then schedule via `PushNotificationService` using the `data` fields above.
- Examples:
  - Fetch string: `Provider.of<LocalizationService>(context, listen: false).getString('expert_support_title')`.
  - Render list: `loc.getString('basic_rules_list').split('\n').map((line) => Text(line))`.

Key places
- `lib/main.dart` (wiring), `lib/services/*` (state/services), `lib/screens/*` (features), `lib/utils/responsive_helper.dart`, `tool/validate_localization.dart`.

When in doubt
- Prefer adding localization keys over literals; go through `DatabaseHelper`; keep platform differences hidden behind existing helpers.
