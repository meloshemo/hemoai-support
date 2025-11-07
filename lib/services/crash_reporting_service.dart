import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../utils/app_constants.dart';
import 'preferences_service.dart';

/// Handles crash reporting configuration and exception forwarding.
class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService _instance = CrashReportingService._();

  factory CrashReportingService() => _instance;

  bool _enabled = false;
  bool _initialized = false;

  bool get isEnabled => _enabled;

  bool get isInitialized => _initialized;

  /// Initializes crash reporting. If disabled or DSN missing, simply runs [appRunner].
  Future<void> initializeAndRun(FutureOr<void> Function() appRunner) async {
    final shouldEnable = AppConstants.enableCrashReporting;
    final dsn = AppConstants.sentryDsn;

    if (!shouldEnable || dsn.isEmpty) {
      debugPrint('CrashReportingService: disabled (missing DSN or flag).');
      _enabled = false;
      await appRunner();
      return;
    }

    final preferences = await PreferencesService.getInstance();
    if (!preferences.allowCrashReporting()) {
      debugPrint('CrashReportingService: disabled by user preference.');
      _enabled = false;
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.release = AppConstants.sentryReleaseIdentifier;
        options.enablePrintBreadcrumbs = !kReleaseMode;
        options.tracesSampleRate =
            kReleaseMode ? AppConstants.sentryTraceSampleRateProd : AppConstants.sentryTraceSampleRateDev;
        options.attachScreenshot = kReleaseMode;
        options.sendDefaultPii = false;
        options.beforeSend = (event, {dynamic hint}) async {
          final prefs = await PreferencesService.getInstance();
          return prefs.allowCrashReporting() ? event : null;
        };
      },
      appRunner: () async {
        _enabled = true;
        _initialized = true;
        await _configureScope();
        await appRunner();
      },
    );
  }

  Future<void> _configureScope() async {
    if (!_enabled) return;

    try {
      final info = await PackageInfo.fromPlatform();
      await Sentry.configureScope((scope) {
        scope.setTag('build_number', info.buildNumber);
        scope.setTag('package_name', info.packageName);
        scope.setTag('app_name', info.appName);
        scope.setTag('platform', describeEnum(defaultTargetPlatform));
      });
    } catch (error) {
      debugPrint('CrashReportingService: scope configuration failed: $error');
    }
  }

  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? hint,
  }) async {
    if (!_enabled) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint,
    );
  }
}


