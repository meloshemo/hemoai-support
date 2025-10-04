# HemoAI: AI coding agent guide

Purpose: Flutter app for hemogram tracking, analysis, reminders, and family features. Use these project-specific rules to be productive fast.

Architecture and key modules
- State management: Provider + ChangeNotifier. Core singletons: `ThemeService`, `NotificationService`, `PushNotificationService`, `LocalizationService`, `ActiveProfileService` (see `lib/services/*`).
- App shell: `lib/main.dart` wires providers, routes, localization delegates, and desktop DB FFI guard (use `kIsWeb` when dealing with `Platform.*`).
- Routing: Use named routes in `MaterialApp.routes`. Examples: `/`, `/analysis`, `/alternative_medicine`, `/notifications`, `/export_options`.
- Data layer (platform aware): Use `DatabaseHelper.instance` for all persistence.
  - Web: falls back to `WebDatabaseHelper` (SharedPreferences-based JSON storage).
  - Desktop/mobile: sqflite (desktop via `sqflite_common_ffi` initialized in `main.dart`).
- Notifications: Two layers
  - `NotificationService` manages in-app reminders list and repeat logic.
  - `PushNotificationService` simulates/schedules "system" notifications, auto-reschedules based on `data['repeat']` and tracks mapping with reminders via `data['reminder_id']`.
- Localization: Centralized in `LocalizationService` with a large key map. Never hardcode user-facing text.

Conventions you must follow
- Text/i18n
  - Always fetch strings via `LocalizationService().getString('key')` or `getStringWithParams('key', {...})`.
  - If adding UI text, first add a key to `lib/services/localization_service.dart` (both `tr` and `en` at minimum) and use it in widgets.
  - Lists are often stored as newline-delimited strings; split with `.split('\n')` (see `basic_rules_list` in `alternative_medicine_screen.dart`).
  - Avoid `const` on widgets that contain dynamic localized `Text` (web compile error otherwise).
  - Run the validator before commits: `tool/validate_localization.dart` flags Turkish literals and missing keys.
- Persistence
  - Do not use `Platform.*` on web. Use `kIsWeb` guard as in `main.dart` and go through `DatabaseHelper` instead of direct packages.
- Notifications
  - When scheduling push for a reminder, include in `data`: `repeat` ('none'|'daily'|'weekly'|'monthly'), `hour`, `minute`, and `reminder_id`. This enables auto-reschedule and mapping cancellation (`PushNotificationService`).
- UI patterns
  - Use `ResponsiveHelper` for grids, spacing, and layout decisions.
  - Use named routes (update `routes` map) and keep providers consistent with `main.dart`.

Typical workflows
- Analyze/lints: VS Code task "flutter-analyze" runs `flutter analyze`.
- Tests: `test/app_smoke_test.dart` expects the same provider set as `main.dart`. If you add providers, mirror them in tests.
- Android setup: `android_setup.bat` accepts SDK licenses and checks devices.
- Web/Desktop DB: Desktop initializes `sqflite_common_ffi`; web uses `SharedPreferences` via `WebDatabaseHelper` transparently.

Integration points and examples
- Localization example: Provider pattern
  - `Provider.of<LocalizationService>(context, listen: false).getString('expert_support_title')`
- Split list example:
  - `loc.getString('basic_rules_list').split('\n').map((line) => Text(line))`
- Schedule startup sync (see `main.dart`): reminders loaded via `WebDatabaseHelper.getReminders(userId)` then scheduled with `PushNotificationService.scheduleNotification(...)` including `data` fields described above.

Files/directories to know
- `lib/main.dart` (app wiring), `lib/services/*` (state/services), `lib/screens/*` (features), `lib/utils/responsive_helper.dart`, `tool/validate_localization.dart`, `docs/LOCALIZATION_CHANGELOG.md` (record notable i18n changes).

When in doubt
- Prefer adding keys to `LocalizationService` over literals.
- Use `DatabaseHelper` and providers rather than ad-hoc singletons.
- Keep web vs native differences behind existing helpers.
