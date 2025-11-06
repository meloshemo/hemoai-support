# 📐 HemoAI Architecture Documentation

## Overview
HemoAI is a health analysis application built with Flutter, supporting multiple platforms (Android, iOS, Web, Windows, macOS, Linux).

## Technology Stack

### Core Framework
- **Flutter SDK:** ^3.5.0
- **Language:** Dart
- **Min iOS:** 11.0
- **Min Android:** API 21

### State Management
- **Provider:** ^6.1.2 (Legacy ChangeNotifier-based)
- **Flutter Riverpod:** ^2.5.1 (Modern state management - future-ready)
- **Riverpod Annotations:** ^2.3.5

### Database & Storage

#### Primary Database: DatabaseHelper
- **Native:** SQLite via `sqflite: ^2.4.2`
- **Web:** SharedPreferences via `WebDatabaseHelper`
- **Desktop:** SQLite FFI via `sqflite_common_ffi: ^2.3.3`
- **Current Version:** 6
- **Location:** `lib/services/database_helper.dart`

**Schema:**
```sql
-- Core Tables
- users (v1)
- hemogram_tests (v1, extended v6)
- family_members (v1)
- family_hemogram_tests (v1)
- medications (v1)
- medication_logs (v1)
- notifications (v1)
- reminders (v1)
- family_invitations (v3)
- water_tracking (v1)
- diet_tracking (v2)
- reminder_streaks (v4)
- reminder_logs (v4)
- emergency_contacts (v5)
- medical_history (v5)
```

**Version 6 Migration:**
Added 13 extended blood test parameters to `hemogram_tests`:
- `glucose`, `alt`, `ast`, `crp`, `tsh`
- `vitamin_d3`, `vitamin_b12`, `calcium`
- `sodium`, `potassium`, `ggt`, `bilirubin`, `creatinine`, `urea`

#### Secondary Database: AppDatabase
- **Platform:** Native only (not available on web)
- **ORM:** Drift ^2.18.0
- **Location:** `lib/core/database/app_database.dart`
- **Usage:** HealthSync service only
- **Purpose:** HealthKit/Google Fit integration

**Note:** On web, HealthSync gracefully skips initialization.

### Routing
- **Current:** MaterialApp NamedRoutes (active)
- **Future:** GoRouter ^14.3.0 (installed but not used)

### Localization
- **Service:** `LocalizationService` (Provider-based)
- **Languages:** TR, EN, AR
- **RTL Support:** Yes (Arabic)
- **Localization Files:** `lib/assets/localizations/*.json`

### Security
- **Password Storage:** FlutterSecureStorage ^9.2.2
- **Encryption:** `cryptography: ^2.7.0`
- **Authentication:** Local with secure hash
- **PII Security:** Migrated to secure storage

### Cloud & Sync
- **Platform:** Supabase ^2.8.0
- **Purpose:** Data backup, cloud sync
- **Service:** `CloudSyncService`
- **Auto Backup:** `AutoBackupService` with Workmanager

### UI & Design
- **Material Design:** 3.0
- **Theme:** Custom `ThemeService` with light/dark modes
- **Charts:** FL Chart ^0.69.0
- **Animations:** Lottie ^3.1.2, Shimmer ^3.0.0
- **Responsive:** Custom `ResponsiveHelper`

### Analysis & AI
- **Health Analysis:** `AnalysisService` (real implementation)
- **AI Analysis:** `AIAnalysisService` (placeholder/mock)
- **Trend Calculation:** Linear regression, moving averages
- **Risk Scoring:** 0-100 scale (lower is better)

### Export & Reporting
- **PDF:** pdf ^3.11.1, printing ^5.13.2
- **Excel:** excel ^4.0.6
- **Web Export:** Conditional dart:html for blob downloads
- **Platform Support:** All platforms (web via conditional imports)

## Project Structure

```
lib/
├── core/                      # Core abstractions
│   ├── database/
│   │   └── app_database.dart  # Drift ORM (HealthSync only)
│   ├── models/
│   ├── providers/             # Riverpod providers (auth)
│   └── services/              # Core services (health sync)
├── repositories/              # Data access layer (SSoT)
│   ├── user_repository.dart
│   ├── hemogram_repository.dart
│   ├── reminder_repository.dart
│   ├── notification_repository.dart
│   ├── medication_repository.dart
│   └── water_repository.dart
├── screens/                   # UI Screens (NamedRoutes)
│   ├── dashboard_screen.dart
│   ├── login_screen.dart
│   ├── analysis_screen.dart
│   ├── hemogram_entry_screen.dart
│   ├── diet_program_screen.dart
│   ├── family_panel_screen.dart
│   ├── notification_screen.dart
│   ├── settings_screen.dart
│   ├── advanced_analytics_screen.dart
│   └── ...
├── services/                  # Business Logic Services
│   ├── database_helper.dart   # Primary database
│   ├── web_database_helper.dart
│   ├── preferences_service.dart
│   ├── analysis_service.dart
│   ├── cloud_sync_service.dart
│   ├── auto_backup_service.dart
│   ├── export_service.dart
│   ├── data_import_service.dart
│   ├── email_service.dart
│   └── ... (many more)
├── widgets/                   # Reusable UI Components
│   ├── app_drawer.dart
│   └── ...
├── utils/                     # Utility Classes
│   ├── color_compat.dart
│   ├── responsive_helper.dart
│   └── ...
└── main.dart                  # App entry point
```

## Key Design Decisions

### 1. Dual Database Strategy
**Rationale:**
- `DatabaseHelper`: Main app data, works on all platforms
- `AppDatabase`: HealthSync only, native platforms
- Avoids complexity of Drift web support

**Trade-offs:**
- Slight code duplication
- Clear separation of concerns
- Platform-specific features work gracefully

### 2. Provider-Based State Management
**Rationale:**
- Established, stable solution
- Good documentation
- Easy to test

**Future Migration:**
- Riverpod installed for future migration
- Current state: Not blocking functionality
- Can be done incrementally

### 3. Conditional Web Imports
**Rationale:**
- `dart:html` only available on web
- Avoids import errors on mobile/desktop
- Pattern: `export_service_web_impl.dart` + stub

**Example:**
```dart
import 'export_service_web_stub.dart' 
  if (dart.library.html) 'export_service_web_impl.dart';
```

### 4. NamedRoutes over GoRouter
**Rationale:**
- Current system works well
- Lower complexity
- Production-ready

**Future:**
- GoRouter installed for potential migration
- Not urgent priority

## Data Flow

### User Registration/Login
```
User Input → LocalizationService → Auth Logic
  → Secure Storage (password) → DatabaseHelper
  → PreferencesService → Session Management
```

### Health Data Entry
```
Manual Entry / Import → Validation
  → DatabaseHelper (insertHemogramTest)
  → AnalysisService (calculate risk)
  → Display Results → Export (optional)
```

### Cloud Sync
```
AutoBackupService (scheduled) → DataCollection
  → Encryption → Supabase → Cloud Storage
  → Cross-Device Sync (if enabled)
```

### Export Workflow
```
ExportService → Generate PDF/Excel
  → Platform-Specific Save/Share
  → Web: blob download
  → Mobile: Share API
  → Desktop: File system
```

## Platform Support

### Android ✅
- **Min SDK:** API 21 (Lollipop 5.0)
- **Target SDK:** Latest
- **Permissions:** Camera, Storage, Notifications
- **Features:** All supported

### iOS ✅
- **Min Version:** 11.0
- **Features:** All supported
- **Permissions:** HealthKit (optional, graceful fallback)

### Web ✅
- **Database:** SharedPreferences
- **Storage:** Browser localStorage
- **Features:** Full export, backup via cloud
- **Limitations:** HealthSync unavailable

### Desktop ✅
- **Platforms:** Windows, macOS, Linux
- **Database:** SQLite FFI
- **Features:** All supported
- **Auto-restore:** Desktop-specific feature

## Migration History

### Database Versions
1. **v1:** Initial schema (users, hemogram_tests, etc.)
2. **v2:** Diet tracking table added
3. **v3:** Family invitations added
4. **v4:** Reminder streaks & logs added
5. **v5:** Emergency contacts & medical history
6. **v6:** Extended blood test parameters (13 new columns)

### Breaking Changes
None - all migrations are additive (ALTER TABLE ADD COLUMN).

## Testing Strategy

### Unit Tests
- Location: `test/`
- Coverage: Services, repositories, business logic
- Framework: Flutter Test

### Widget Tests
- Location: `test/widgets/`
- Coverage: UI components
- Status: Basic coverage

### Integration Tests
- Location: `integration_test/`
- Coverage: Critical user flows
- Status: Planned

## Performance Considerations

### Database Optimization
- Indexes on frequently queried fields
- Lazy loading for large datasets
- Query optimization in repositories

### UI Performance
- ListView builders for large lists
- Image caching via `cached_network_image`
- Animation performance via `TickerProvider`

### Memory Management
- Proper disposal of controllers
- Single instance services
- Efficient state management

## Security Considerations

### Data Protection
- Password hashing (SHA-256)
- Secure storage for PII
- Encrypted backups
- Audit logging

### Privacy
- GDPR compliant data handling
- User consent for data collection
- Data export/delete capabilities
- Privacy policy integration

## Future Enhancements

### Potential Migrations
1. **Provider → Riverpod:** Incremental migration
2. **NamedRoutes → GoRouter:** If navigation becomes complex
3. **Drift web support:** If HealthSync is needed on web

### Planned Features
1. Advanced AI analysis
2. HealthKit/Google Fit deep integration
3. e-Devlet real API integration
4. Multi-language expansion
5. Advanced analytics

## Contributing

### Code Style
- Follow Flutter/Dart style guide
- Use `flutter format` before commit
- No linter errors (run `flutter analyze`)

### Testing
- Add tests for new features
- Maintain coverage >80%
- Integration tests for critical flows

### Documentation
- Update this file for architectural changes
- Document public APIs
- Add inline comments for complex logic

## References

### External Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Drift ORM](https://drift.simonbinder.eu/)
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Provider Pattern](https://pub.dev/packages/provider)

### Internal Documentation
- `docs/PLAY_STORE_PUBLICATION_SUMMARY.md`
- `docs/PRODUCTION_FEATURES_COMPLETE.md`
- `docs/DEEP_AUDIT_REPORT.md`
- `docs/FINAL_IMPROVEMENTS_SUMMARY.md`

---

**Last Updated:** 2024
**Version:** 4.0.0+400
**Maintainer:** HemoAI Development Team

