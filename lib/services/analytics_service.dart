import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'preferences_service.dart';

/// Privacy-preserving, opt-in analytics service.
/// - Disabled by default; gated by PreferencesService key 'analytics_opt_in'.
/// - When enabled, only logs anonymized screen and event names locally (debugPrint).
/// - No network calls; safe for all platforms.
class AnalyticsService extends ChangeNotifier {
  static const String _prefKey = 'analytics_opt_in';

  bool _optedIn = false;
  bool get optedIn => _optedIn;

  Future<void> initialize() async {
    try {
      final prefs = await PreferencesService.getInstance();
      _optedIn = prefs.getCustomSetting<bool>(_prefKey) ?? false;
    } catch (e) {
      debugPrint('[Analytics] initialize failed: $e');
      _optedIn = false;
    }
  }

  Future<void> setOptIn(bool value) async {
    try {
      final prefs = await PreferencesService.getInstance();
      await prefs.saveCustomSettings(_prefKey, value);
      _optedIn = value;
      notifyListeners();
      debugPrint('[Analytics] opt-in set to: $value');
    } catch (e) {
      debugPrint('[Analytics] setOptIn failed: $e');
    }
  }

  void trackScreenView(String screenName) {
    if (!_optedIn) return;
    // Local log only; no PII
    debugPrint('[Analytics] screen: $screenName');
  }

  void trackEvent(String name, {Map<String, Object?> parameters = const {}}) {
    if (!_optedIn) return;
    // Local log only; no PII
    debugPrint('[Analytics] event: $name params: $parameters');
  }
}
