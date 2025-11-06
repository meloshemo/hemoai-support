# HemoAI API Documentation

**Version:** 4.0.0+400  
**Last Updated:** 2025-01-27

---

## 📚 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Services API](#services-api)
3. [Repositories API](#repositories-api)
4. [Widgets API](#widgets-api)
5. [Utilities API](#utilities-api)
6. [Models API](#models-api)

---

## Architecture Overview

HemoAI follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── core/           # Core business logic
│   ├── services/   # Business services
│   ├── providers/  # State management
│   └── database/   # Data layer
├── services/       # Application services
├── repositories/   # Data access layer
├── screens/        # UI screens
├── widgets/        # Reusable widgets
└── utils/          # Utility functions
```

---

## Services API

### NetworkService

**Location:** `lib/services/network_service.dart`

Professional network connectivity service with real-time monitoring.

```dart
// Initialize
await NetworkService().initialize();

// Check connectivity
final isConnected = NetworkService().isConnected;
final status = await NetworkService().checkConnectivity();

// Check internet access
final hasInternet = await NetworkService().hasInternetAccess();

// Get status text
final statusText = NetworkService().getNetworkStatusText();
```

**Properties:**
- `isInitialized` - Service initialization status
- `isConnected` - Current connection status
- `currentStatus` - ConnectivityResult

**Methods:**
- `initialize()` - Initialize service
- `checkConnectivity()` - Check current connectivity
- `hasInternetAccess()` - Verify actual internet access
- `getNetworkStatusText()` - Human-readable status

---

### ErrorHandler

**Location:** `lib/utils/error_handler.dart`

Global error handling with user-friendly messages.

```dart
// Handle error
await ErrorHandler().handleError(
  context,
  error,
  stackTrace: stackTrace,
  customMessage: 'Custom error message',
  onRetry: () => retryOperation(),
);

// Safe async operation
final result = await ErrorHandler().safeAsync(
  () => riskyOperation(),
  context: context,
  defaultValue: null,
);

// Network-aware operation
final result = await ErrorHandler().withNetworkCheck(
  context,
  () => networkOperation(),
);
```

**Custom Exceptions:**
- `NetworkException` - Network errors
- `ValidationException` - Validation errors
- `DatabaseException` - Database errors
- `PermissionException` - Permission errors
- `TimeoutException` - Timeout errors

---

### Validators

**Location:** `lib/utils/validators.dart`

Comprehensive input validation utilities.

```dart
// Email validation
String? error = Validators.validateEmail(value);

// Phone validation
String? error = Validators.validatePhone(value, isTurkish: true);

// Password validation
String? error = Validators.validatePassword(
  value,
  minLength: 8,
  requireUppercase: true,
  requireNumbers: true,
);

// Numeric range
String? error = Validators.validateNumericRange(
  value,
  min: 0,
  max: 100,
  fieldName: 'Age',
);

// Combine validators
String? error = Validators.combineValidators(
  value,
  [
    (v) => Validators.validateRequired(v),
    (v) => Validators.validateEmail(v),
  ],
);
```

**Available Validators:**
- `validateEmail()` - Email format
- `validatePhone()` - Phone number
- `validatePassword()` - Password strength
- `validatePasswordConfirmation()` - Password match
- `validateName()` - Name format
- `validateNumericRange()` - Number range
- `validateTCKimlik()` - Turkish ID number
- `validateAge()`, `validateHeight()`, `validateWeight()` - Health data
- `validateOtp()` - OTP code
- `validateUrl()` - URL format
- `validateDate()` - Date format

---

### DeepLinkHandler

**Location:** `lib/utils/deep_link_handler.dart`

Professional deep linking handler.

```dart
// Handle deep link
await DeepLinkHandler().handleDeepLink(
  'hemoai://app/analysis',
  context: context,
);

// Generate deep link
final link = DeepLinkHandler().generateDeepLink(
  route: '/analysis',
  parameters: {'testId': '123'},
);

// Generate universal link
final universalLink = DeepLinkHandler().generateUniversalLink(
  route: '/family_panel',
  parameters: {'memberId': '456'},
);
```

**Supported Formats:**
- Custom scheme: `hemoai://app/route?param=value`
- Universal links: `https://hemoai.app/route?param=value`

---

### OfflineService

**Location:** `lib/services/offline_service.dart`

Offline-first service with queue system.

```dart
// Queue operation
await OfflineService().queueOperation(
  operationType: 'sync_data',
  data: {'userId': 123},
  execute: (data) => syncData(data),
);

// Sync queue
await OfflineService().syncQueue();

// Get queue status
final queueSize = OfflineService().queueSize;
final hasQueued = OfflineService().hasQueuedOperations;
```

**Properties:**
- `queueSize` - Number of queued operations
- `isSyncing` - Sync status
- `hasQueuedOperations` - Queue status

---

### SecurityService

**Location:** `lib/services/security_service.dart`

Security hardening service.

```dart
// Store API key securely
await SecurityService().storeApiKey('api_key', 'value');

// Get API key
final key = await SecurityService().getApiKey('api_key');

// Rate limiting
if (!SecurityService().checkRateLimit('user_123')) {
  // Rate limited
}

// Sanitize input
final safe = SecurityService().sanitizeInput(userInput);

// Generate secure token
final token = SecurityService().generateSecureToken(length: 32);
```

**Features:**
- Secure storage (flutter_secure_storage)
- Rate limiting (10 req/min default)
- Input sanitization
- Certificate pinning framework
- Secure token generation

---

### BackgroundTaskService

**Location:** `lib/services/background_task_service.dart`

Background task management.

```dart
// Initialize
await BackgroundTaskService().initialize();

// Register periodic sync
await BackgroundTaskService().registerPeriodicSync(
  frequency: Duration(hours: 6),
);

// Register one-time task
await BackgroundTaskService().registerOneTimeTask(
  taskName: 'sync_now',
  delay: Duration(minutes: 5),
  inputData: {'param': 'value'},
);

// Cancel task
await BackgroundTaskService().cancelTask('task_name');
```

---

### EnhancedAnalyticsService

**Location:** `lib/services/enhanced_analytics_service.dart`

Professional analytics with privacy-first approach.

```dart
// Initialize
await EnhancedAnalyticsService().initialize();

// Track screen view
EnhancedAnalyticsService().trackScreenView('dashboard');

// Track event
EnhancedAnalyticsService().trackEvent(
  'button_clicked',
  parameters: {'button': 'save'},
);

// Track user action
EnhancedAnalyticsService().trackUserAction('save_data');

// Track error
EnhancedAnalyticsService().trackError(
  'Error message',
  stackTrace: stackTrace,
);

// Track performance
EnhancedAnalyticsService().trackPerformance(
  'api_call',
  Duration(milliseconds: 500),
);
```

---

## Repositories API

### UserRepository

**Location:** `lib/repositories/user_repository.dart`

User data access.

```dart
final userRepo = UserRepository();

// Get user
final user = await userRepo.getUserById(userId);

// Create user
final userId = await userRepo.createUser(userData);

// Update user
await userRepo.updateUser(userId, userData);

// Delete user
await userRepo.deleteUser(userId);
```

---

### HemogramRepository

**Location:** `lib/repositories/hemogram_repository.dart`

Hemogram test data access.

```dart
final hemogramRepo = HemogramRepository();

// Get hemogram test
final test = await hemogramRepo.getHemogramTestById(testId);

// Get latest test
final latest = await hemogramRepo.getLatestHemogramTest(userId);

// Create hemogram test
final testId = await hemogramRepo.createHemogramTest(testData);

// Get test history
final history = await hemogramRepo.getHemogramTestHistory(userId);
```

---

## Widgets API

### LoadingState

**Location:** `lib/widgets/loading_state.dart`

Professional loading state widget.

```dart
LoadingState(
  message: 'Loading data...',
  showProgressIndicator: true,
)
```

### EmptyState

**Location:** `lib/widgets/empty_state.dart`

Empty state widget.

```dart
EmptyState(
  icon: Icons.inbox,
  title: 'No data found',
  message: 'Start by adding your first item',
  actionLabel: 'Add Item',
  onAction: () => addItem(),
)
```

### AccessibleWidgets

**Location:** `lib/widgets/accessible_widgets.dart`

Accessibility-enhanced widgets.

```dart
AccessibleButton(
  onPressed: () => {},
  semanticLabel: 'Save data',
  child: Text('Save'),
)

AccessibleTextField(
  labelText: 'Name',
  semanticLabel: 'Name input field',
)
```

### UI Enhancements

**Location:** `lib/widgets/ui_enhancements.dart`

Modern UI components.

```dart
// Pull to refresh
PullToRefreshWrapper(
  onRefresh: () => loadData(),
  child: ListView(...),
)

// Debounced search
DebouncedSearchBar(
  onChanged: (query) => search(query),
  hintText: 'Search...',
)

// Animated counter
AnimatedCounter(value: count)

// Gradient card
GradientCard(
  colors: [Colors.blue, Colors.purple],
  child: Content(),
)
```

---

## Utilities API

### PerformanceUtils

**Location:** `lib/utils/performance_utils.dart`

Performance optimization utilities.

```dart
// Debounce function
final debounced = PerformanceUtils.debounce(() => doSomething());

// Throttle function
final throttled = PerformanceUtils.throttle(() => doSomething());

// Memoize
final result = PerformanceUtils.memoize('key', () => expensiveComputation());

// Optimized image
PerformanceUtils.optimizedImage(
  imagePath: 'assets/image.png',
  width: 100,
  height: 100,
)
```

### Localization Extensions

**Location:** `lib/utils/localization_extensions.dart`

Easy localization access.

```dart
// Using extension
final text = context.t('welcome');
final textWithParams = context.tParams('hello', {'name': 'John'});

// Format date
final date = LocalizationHelper.formatDate(context, DateTime.now());

// Format number
final number = LocalizationHelper.formatNumber(context, 123.45);
```

---

## Models API

### UserModel

**Location:** `lib/models/user_model.dart`

User data model.

```dart
final user = UserModel(
  id: 1,
  name: 'John Doe',
  email: 'john@example.com',
  age: 30,
  gender: 'male',
);
```

### BloodTestResult

**Location:** `lib/models/blood_test_model.dart`

Blood test result model.

```dart
final testResult = BloodTestResult(
  values: {
    'hemoglobin': 14.5,
    'iron': 120.0,
  },
  testDate: DateTime.now(),
);
```

---

## Error Handling

All services follow consistent error handling patterns:

1. **Try-catch blocks** for all async operations
2. **User-friendly messages** via ErrorHandler
3. **Logging** for debugging
4. **Fallback values** where appropriate

---

## Best Practices

1. **Always use repositories** for data access
2. **Use services** for business logic
3. **Validate inputs** before processing
4. **Handle errors gracefully** with ErrorHandler
5. **Use localization** for all user-facing text
6. **Check network** before network operations
7. **Use offline service** for critical operations

---

## Migration Guide

### From Old Analytics to Enhanced

```dart
// Old
AnalyticsService().trackEvent('event');

// New
EnhancedAnalyticsService().trackEvent('event', parameters: {...});
```

### From Hardcoded Strings to Localization

```dart
// Old
Text('Welcome')

// New
Text(context.t('welcome'))
// or
Text(localizationService.getString('welcome'))
```

---

## Testing

All services are designed to be testable:

```dart
// Mock services in tests
final mockNetworkService = MockNetworkService();
final mockErrorHandler = MockErrorHandler();
```

---

**Last Updated:** 2025-01-27  
**Maintainer:** HemoAI Development Team

