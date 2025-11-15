import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'preferences_service.dart';

/// Opt-in analytics service backed by Firebase Analytics with graceful
/// fallbacks for unsupported platforms.
class AnalyticsService extends ChangeNotifier {
  AnalyticsService();

  static const String _prefKey = 'analytics_opt_in';

  FirebaseAnalytics? _analytics;

  bool _optedIn = false;
  bool get optedIn => _optedIn;

  Future<void> initialize() async {
    try {
      final prefs = await PreferencesService.getInstance();
      _optedIn = prefs.getCustomSetting<bool>(_prefKey) ?? false;
    } catch (e, stack) {
      debugPrint('[Analytics] initialize preference read failed: $e');
      debugPrintStack(stackTrace: stack);
      _optedIn = false;
    }

    await _setupFirebaseAnalytics();
  }

  Future<void> setOptIn(bool value) async {
    try {
      final prefs = await PreferencesService.getInstance();
      await prefs.saveCustomSettings(_prefKey, value);
      _optedIn = value;
      await _applyCollectionPreference();
      notifyListeners();
      debugPrint('[Analytics] opt-in set to: $value');
    } catch (e, stack) {
      debugPrint('[Analytics] setOptIn failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> trackScreenView(String screenName) async {
    if (!_optedIn) return;
    debugPrint('[Analytics] screen: $screenName');
    final analytics = _analytics;
    if (analytics == null) return;

    try {
      await analytics.logScreenView(
        screenClass: screenName,
        screenName: screenName,
      );
    } catch (e, stack) {
      debugPrint('[Analytics] logScreenView failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    if (!_optedIn) return;
    debugPrint('[Analytics] event: $name params: $parameters');

    final analytics = _analytics;
    if (analytics == null) return;

    try {
      final sanitizedParams = _sanitizeParameters(parameters);
      await analytics.logEvent(
        name: _sanitizeEventName(name),
        parameters: sanitizedParams.isEmpty ? null : sanitizedParams,
      );
    } catch (e, stack) {
      debugPrint('[Analytics] logEvent failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _setupFirebaseAnalytics() async {
    if (!_isSupportedPlatform) {
      debugPrint(
          '[Analytics] Firebase Analytics unsupported platform; using local logging only');
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      await _applyCollectionPreference();
      debugPrint('[Analytics] Firebase Analytics ready (optedIn=$_optedIn)');
    } catch (e, stack) {
      debugPrint('[Analytics] Firebase Analytics init failed: $e');
      debugPrintStack(stackTrace: stack);
      _analytics = null;
    }
  }

  Future<void> _applyCollectionPreference() async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setAnalyticsCollectionEnabled(_optedIn);
    } catch (e, stack) {
      debugPrint('[Analytics] setAnalyticsCollectionEnabled failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return {
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }.contains(defaultTargetPlatform);
  }

  String _sanitizeEventName(String name) {
    final sanitized = name.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '_');
    return sanitized.isEmpty ? 'custom_event' : sanitized;
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> params) {
    final sanitized = <String, Object>{};
    params.forEach((key, value) {
      final cleanKey =
          key.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '_');
      if (cleanKey.isEmpty) return;
      if (value == null) return;
      if (value is num || value is String || value is bool) {
        sanitized[cleanKey] = value;
      } else {
        sanitized[cleanKey] = value.toString();
      }
    });
    return sanitized;
  }
}
