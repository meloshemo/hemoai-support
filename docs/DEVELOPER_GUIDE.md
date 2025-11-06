# HemoAI Developer Guide

**Version:** 4.0.0+400  
**Last Updated:** 2025-01-27

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.5.0 or higher
- Android Studio / VS Code
- Git

### Setup

```bash
# Clone repository
git clone <repository-url>
cd hemoai

# Install dependencies
flutter pub get

# Run app
flutter run
```

---

## 📁 Project Structure

```
lib/
├── core/                    # Core business logic
│   ├── services/           # Core services (AI, Health, Auth)
│   ├── providers/          # State management providers
│   ├── database/           # Database schema (Drift)
│   └── models/             # Core models
├── services/               # Application services
│   ├── network_service.dart
│   ├── security_service.dart
│   ├── offline_service.dart
│   └── ...
├── repositories/           # Data access layer
│   ├── user_repository.dart
│   ├── hemogram_repository.dart
│   └── ...
├── screens/                # UI screens
├── widgets/                # Reusable widgets
│   ├── loading_state.dart
│   ├── empty_state.dart
│   ├── accessible_widgets.dart
│   └── ui_enhancements.dart
└── utils/                  # Utilities
    ├── validators.dart
    ├── error_handler.dart
    ├── performance_utils.dart
    └── localization_extensions.dart
```

---

## 🏗️ Architecture Patterns

### State Management

**Provider Pattern:**
- Services use `ChangeNotifier`
- Repositories are stateless
- UI consumes via `Provider.of()` or `Consumer`

```dart
// Service
class MyService extends ChangeNotifier {
  void update() {
    notifyListeners();
  }
}

// Widget
Consumer<MyService>(
  builder: (context, service, child) {
    return Text(service.value);
  },
)
```

### Data Flow

```
UI → Service → Repository → Database
     ↓
  Provider
```

---

## 🔧 Common Tasks

### Adding a New Screen

1. Create screen file in `lib/screens/`
2. Add route in `lib/main.dart`
3. Add navigation in drawer/menu
4. Add localization keys

```dart
// lib/screens/my_screen.dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('my_screen'))),
      body: Container(),
    );
  }
}
```

### Adding a New Service

1. Create service file in `lib/services/`
2. Implement singleton pattern
3. Add to Provider in `main.dart`
4. Initialize in `main()`

```dart
// lib/services/my_service.dart
class MyService extends ChangeNotifier {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  MyService._internal();

  Future<void> initialize() async {
    // Initialization logic
  }
}
```

### Adding Localization Keys

1. Add keys to `lib/services/localization_service.dart`
2. Add translations for all languages
3. Use in UI: `context.t('key')` or `loc.getString('key')`

```dart
'my_key': {
  'tr': 'Türkçe metin',
  'en': 'English text',
  'es': 'Texto en español',
  // ... other languages
},
```

---

## 🧪 Testing

### Unit Tests

```dart
// test/services/my_service_test.dart
void main() {
  group('MyService', () {
    test('should initialize', () async {
      final service = MyService();
      await service.initialize();
      expect(service.isInitialized, true);
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/my_widget_test.dart
void main() {
  testWidgets('MyWidget displays correctly', (tester) async {
    await tester.pumpWidget(MyWidget());
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

---

## 🔒 Security Best Practices

1. **Never commit API keys** - Use environment variables
2. **Sanitize user input** - Use `SecurityService.sanitizeInput()`
3. **Store sensitive data securely** - Use `SecurityService.storeApiKey()`
4. **Validate all inputs** - Use `Validators` class
5. **Check network before operations** - Use `NetworkService`

---

## 📱 Platform-Specific Considerations

### Web

- Use `WebDatabaseHelper` for persistence
- Network checks work automatically
- No native background tasks

### Mobile (Android/iOS)

- Use `DatabaseHelper` (sqflite)
- Background tasks via WorkManager
- Platform-specific permissions

### Desktop (Windows/Linux/macOS)

- Use `sqflite_common_ffi`
- Initialize in `main.dart`
- No background tasks

---

## 🐛 Debugging

### Common Issues

1. **Network errors**: Check `NetworkService.isConnected`
2. **Database errors**: Check database initialization
3. **Localization errors**: Run `tool/validate_localization.dart`
4. **Memory leaks**: Check dispose() methods

### Debug Tools

```dart
// Enable debug logging
if (kDebugMode) {
  debugPrint('Debug message');
}

// Use Logger
final logger = Logger();
logger.i('Info message');
logger.e('Error message', error: error);
```

---

## 📚 Code Style

### Naming Conventions

- **Classes**: PascalCase (`MyService`)
- **Variables**: camelCase (`myVariable`)
- **Files**: snake_case (`my_service.dart`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_SIZE`)

### File Organization

- One class per file
- Related classes in same directory
- Imports in order: flutter, packages, local

```dart
// Import order
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/my_service.dart';
```

---

## 🚀 Performance Tips

1. **Use ListView.builder** for long lists
2. **Memoize expensive computations** with `PerformanceUtils.memoize()`
3. **Debounce/throttle** frequent operations
4. **Lazy load** data with pagination
5. **Cache images** with proper sizing

---

## 📖 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Drift Documentation](https://drift.simonbinder.eu/)

---

**Last Updated:** 2025-01-27

