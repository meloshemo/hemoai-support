import 'dart:async';

import 'package:flutter/foundation.dart';

/// Minimal no-op crash reporting stub to avoid build-time errors when Sentry
/// or related configuration isn't available. Preserves the public API expected
/// by the app without introducing external dependencies.
class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService _instance = CrashReportingService._();

  factory CrashReportingService() => _instance;

  bool _enabled = false;
  bool _initialized = false;

  bool get isEnabled => _enabled;

  bool get isInitialized => _initialized;

  /// Initializes crash reporting. In this stub, we simply run the app.
  Future<void> initializeAndRun(FutureOr<void> Function() appRunner) async {
    debugPrint('CrashReportingService(stub): disabled. Running app without Sentry.');
    _enabled = false;
    _initialized = true;
    await appRunner();
  }

  /// Capture an exception (no-op in stub).
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? hint,
  }) async {
    // Intentionally no-op.
    if (kDebugMode) {
      debugPrint('CrashReportingService(stub): captureException called: $exception');
    }
  }
}


