import 'package:logger/logger.dart';
import 'preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Professional analytics service with privacy-first approach
/// Supports multiple analytics providers (Firebase, custom, local-only)
class EnhancedAnalyticsService {
  static final EnhancedAnalyticsService _instance = EnhancedAnalyticsService._internal();
  factory EnhancedAnalyticsService() => _instance;
  EnhancedAnalyticsService._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;
  bool _optedIn = false;
  static const String _prefKey = 'analytics_opt_in';

  // Analytics providers
  bool _firebaseEnabled = false;
  bool _localOnlyEnabled = true; // Default: local-only analytics

  // Event queue for batch processing
  final List<AnalyticsEvent> _eventQueue = [];
  static const int _maxQueueSize = 100;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await PreferencesService.getInstance();
      _optedIn = prefs.getCustomSetting<bool>(_prefKey) ?? false;

      // Check for Firebase availability (optional)
      // if (Firebase.apps.isNotEmpty) {
      //   _firebaseEnabled = true;
      // }

      _isInitialized = true;
      _logger.i('EnhancedAnalyticsService initialized (opted in: $_optedIn)');
    } catch (e) {
      _logger.e('Failed to initialize EnhancedAnalyticsService: $e');
      _isInitialized = false;
    }
  }

  /// Set analytics opt-in status
  Future<void> setOptIn(bool value) async {
    try {
      final prefs = await PreferencesService.getInstance();
      await prefs.saveCustomSettings(_prefKey, value);
      _optedIn = value;
      _logger.i('Analytics opt-in set to: $value');
    } catch (e) {
      _logger.e('Failed to set analytics opt-in: $e');
    }
  }

  bool get optedIn => _optedIn;
  bool get isInitialized => _isInitialized;

  /// Track screen view
  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    if (!_optedIn || !_isInitialized) return;

    final event = AnalyticsEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        ...?parameters,
      },
      timestamp: DateTime.now(),
    );

    _logEvent(event);
  }

  /// Track custom event
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_optedIn || !_isInitialized) return;

    final event = AnalyticsEvent(
      name: eventName,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    );

    _logEvent(event);
  }

  /// Track user action
  void trackUserAction(String action, {Map<String, dynamic>? parameters}) {
    trackEvent('user_action', parameters: {
      'action': action,
      ...?parameters,
    });
  }

  /// Track error
  void trackError(String error, {StackTrace? stackTrace, Map<String, dynamic>? parameters}) {
    if (!_optedIn || !_isInitialized) return;

    trackEvent('error_occurred', parameters: {
      'error_message': error,
      'has_stack_trace': stackTrace != null,
      ...?parameters,
    });

    // Log to local storage for debugging
    _logErrorToLocal(error, stackTrace);
  }

  /// Track performance metric
  void trackPerformance(String metricName, Duration duration, {Map<String, dynamic>? parameters}) {
    trackEvent('performance_metric', parameters: {
      'metric_name': metricName,
      'duration_ms': duration.inMilliseconds,
      ...?parameters,
    });
  }

  /// Track conversion/purchase
  void trackConversion(String conversionType, {double? value, String? currency, Map<String, dynamic>? parameters}) {
    trackEvent('conversion', parameters: {
      'conversion_type': conversionType,
      if (value != null) 'value': value,
      if (currency != null) 'currency': currency,
      ...?parameters,
    });
  }

  /// Log event internally
  void _logEvent(AnalyticsEvent event) {
    // Add to queue
    _eventQueue.add(event);
    if (_eventQueue.length > _maxQueueSize) {
      _eventQueue.removeAt(0); // Remove oldest
    }

    // Local-only logging
    if (_localOnlyEnabled) {
      _logger.d('[Analytics] ${event.name}: ${event.parameters}');
    }

    // Firebase Analytics (if enabled)
    // if (_firebaseEnabled) {
    //   FirebaseAnalytics.instance.logEvent(
    //     name: event.name,
    //     parameters: event.parameters,
    //   );
    // }

    // Custom analytics endpoint (if configured)
    // _sendToCustomEndpoint(event);
  }

  /// Log error to local storage
  void _logErrorToLocal(String error, StackTrace? stackTrace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList('analytics_error_logs') ?? [];
      
      final errorEntry = {
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
        'has_stack': stackTrace != null,
      }.toString();

      errorLogs.add(errorEntry);
      
      // Keep only last 50 errors
      if (errorLogs.length > 50) {
        errorLogs.removeAt(0);
      }

      await prefs.setStringList('analytics_error_logs', errorLogs);
    } catch (e) {
      _logger.e('Failed to log error locally: $e');
    }
  }

  /// Get analytics summary
  Future<AnalyticsSummary> getSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList('analytics_error_logs') ?? [];
      
      return AnalyticsSummary(
        totalEvents: _eventQueue.length,
        errorCount: errorLogs.length,
        lastEventTime: _eventQueue.isNotEmpty ? _eventQueue.last.timestamp : null,
      );
    } catch (e) {
      _logger.e('Failed to get analytics summary: $e');
      return AnalyticsSummary(
        totalEvents: 0,
        errorCount: 0,
        lastEventTime: null,
      );
    }
  }

  /// Clear analytics data
  Future<void> clearAnalyticsData() async {
    try {
      _eventQueue.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('analytics_error_logs');
      _logger.i('Analytics data cleared');
    } catch (e) {
      _logger.e('Failed to clear analytics data: $e');
    }
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
}

/// Analytics summary
class AnalyticsSummary {
  final int totalEvents;
  final int errorCount;
  final DateTime? lastEventTime;

  AnalyticsSummary({
    required this.totalEvents,
    required this.errorCount,
    this.lastEventTime,
  });
}

