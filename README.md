# HemoAI — Smart Hemogram Analysis & Health Tracking

**HemoAI** is a Flutter app for hemogram tracking, AI-assisted analysis, personalized diet recommendations, alternative medicine insights, and family health management.

**Status:** ✅ Production-ready • **Version:** 4.0.0+400  
**Latest:** All critical and medium-priority improvements completed! ✨✨  
**Platforms:** Android • Web • Windows • iOS • macOS • Linux

## 🎯 Recent Improvements

### ✅ Critical Fixes (5/5)
- Network connectivity monitoring
- Deep linking support
- Memory leak fixes
- Comprehensive error handling
- Input validation

### ✅ Medium Priority (7/7)
- Test coverage foundation
- Accessibility support
- Loading/Empty states
- Offline mode handling
- XML/HTML import
- Background tasks
- Security hardening

### ✅ Low Priority (5/5)
- Performance optimizations
- UI/UX enhancements
- Localization improvements
- Analytics integration
- Documentation improvements

## 🚀 Ready for Production!

This app is **fully prepared** for production deployment. All builds, documentation, and production features are complete.

**👉 Latest Improvements:** Read [`FINAL_IMPROVEMENTS_COMPLETE.md`](FINAL_IMPROVEMENTS_COMPLETE.md) 🎯 **NEW!**  
**App Analysis:** Read [`APP_ANALYSIS_REPORT.md`](APP_ANALYSIS_REPORT.md) 🎯  
**Production setup:** Read [`START_HERE_NOW.md`](START_HERE_NOW.md) ⭐  
**Quick config:** Read [`QUICK_START_PRODUCTION.md`](QUICK_START_PRODUCTION.md) ⚡  
**All features:** Read [`FINAL_PRODUCTION_README.md`](FINAL_PRODUCTION_README.md)  
**Play Store:** Read [`START_HERE.md`](START_HERE.md)  
**All docs:** See [`docs/README_DOCS.md`](docs/README_DOCS.md)

## Highlights (OS 4)
- Analysis: Smart summary with risk score and flagged findings
- Reminders: streaks, mark as done, snooze 10m
- Settings: improved discoverability; About shows version/release name

### New in this workspace session
- Marker-aware Diet Program: personalized diet cards now react to popular markers like glucose, liver enzymes (ALT/AST/GGT), bilirubin, CRP, thyroid (TSH/Free T3/T4), vitamin D3, vitamin B12, electrolytes (Na/K/Cl), and calcium.
- Alternative Medicine: new herbal categories added (Glucose Control, Liver Support, Bilirubin Support, Thyroid Support, Vitamin D Support, B12 Support, Electrolyte Balance, Calcium Support) with localized herb suggestions and safety notes.
- Localization: all new content is localized (TR/EN). See `docs/LOCALIZATION_CHANGELOG.md`.

## 🚀 Quick Start

### Run the App

```bash
# Web
flutter run -d edge

# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Development Tools

```bash
# Validate localization
dart run tool/validate_localization.dart

# Static analysis
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean && flutter pub get
```

## 📖 Documentation

- **[API Documentation](docs/API_DOCUMENTATION.md)** - Complete API reference
- **[Developer Guide](docs/DEVELOPER_GUIDE.md)** - Development guidelines
- **[Play Store Guide](docs/PLAY_STORE_PUBLICATION_SUMMARY.md)** - Publication checklist
- **[Architecture](docs/ARCHITECTURE.md)** - System architecture
- **[All Documentation](docs/README_DOCS.md)** - Complete docs index

## Project conventions
- State and services use Provider + ChangeNotifier. Core singletons: `ThemeService`, `NotificationService`, `PushNotificationService`, `LocalizationService`, `ActiveProfileService` (see `lib/services/*`).
- Routes: named routes via `MaterialApp.routes` (e.g., `/`, `/analysis`, `/notifications`, `/export_options`).
- Persistence: always go through `DatabaseHelper.instance`.
	- Web uses `WebDatabaseHelper` (SharedPreferences-backed JSON).
	- Mobile/Desktop use sqflite; desktop initializes `sqflite_common_ffi` in `main.dart`.
- Notifications:
	- `NotificationService` keeps the in-app list and repeat logic.
	- `PushNotificationService` simulates/schedules system notifications, auto-reschedules using `data['repeat']`, tracks mapping with `data['reminder_id']`.
- Localization: never hardcode user-facing text.
	- Use `LocalizationService().getString('key')` or `getStringWithParams('key', {...})`.
	- Run `tool/validate_localization.dart` before commit to catch missing keys.
	- When adding UI text, add TR/EN keys first; lists are often newline-delimited strings.

## Dev tips
- Prefer `ResponsiveHelper` for layout.
- Guard `Platform.*` with `kIsWeb` and keep platform differences behind helpers.
- When adding providers, mirror them in tests.

## Cleanup note
Build artifacts, logs, and ephemeral platform folders are intentionally excluded/cleaned to keep OS 4 the clear focus. If you need to regenerate, use `flutter clean` and re-run the app.

