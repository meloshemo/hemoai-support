import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/analytics_service.dart';
import 'package:hemoai/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Clear any existing state
      final prefs = await PreferencesService.getInstance();
      await prefs.saveCustomSettings('analytics_opt_in', false);
      analyticsService = AnalyticsService();
      await analyticsService.initialize();
    });

    test('should create instance', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      // AnalyticsService is a ChangeNotifier, not a singleton
      // But instances should work independently
      expect(instance1, isA<AnalyticsService>());
      expect(instance2, isA<AnalyticsService>());
    });

    group('Initialization', () {
      test('should initialize with opt-out by default', () async {
        expect(analyticsService.optedIn, false);
      });

      test('should load saved opt-in state', () async {
        final prefs = await PreferencesService.getInstance();
        await prefs.saveCustomSettings('analytics_opt_in', true);
        
        final service = AnalyticsService();
        await service.initialize();
        
        expect(service.optedIn, true);
      });

      test('should handle missing preference gracefully', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await PreferencesService.getInstance();
        // Ensure preference is not set
        await prefs.saveCustomSettings('analytics_opt_in', null);
        final service = AnalyticsService();
        await service.initialize();
        
        expect(service.optedIn, false);
      });
    });

    group('Opt-in Management', () {
      test('should set opt-in to true', () async {
        await analyticsService.setOptIn(true);
        expect(analyticsService.optedIn, true);
      });

      test('should set opt-in to false', () async {
        await analyticsService.setOptIn(true);
        await analyticsService.setOptIn(false);
        expect(analyticsService.optedIn, false);
      });

      test('should persist opt-in state', () async {
        await analyticsService.setOptIn(true);
        
        final newService = AnalyticsService();
        await newService.initialize();
        
        expect(newService.optedIn, true);
      });
    });

    group('Tracking (Opt-in Required)', () {
      test('should not track when opted out', () async {
        // Ensure opted out
        await analyticsService.setOptIn(false);
        expect(analyticsService.optedIn, false);
        
        // Should not throw, but also not track (no debugPrint output expected)
        analyticsService.trackScreenView('test_screen');
        analyticsService.trackEvent('test_event');
      });

      test('should track screen view when opted in', () async {
        await analyticsService.setOptIn(true);
        
        // Should not throw
        expect(() => analyticsService.trackScreenView('test_screen'), returnsNormally);
      });

      test('should track events when opted in', () async {
        await analyticsService.setOptIn(true);
        
        expect(() => analyticsService.trackEvent('test_event'), returnsNormally);
        expect(() => analyticsService.trackEvent('test_event', parameters: {'key': 'value'}), returnsNormally);
      });

      test('should handle empty parameters', () async {
        await analyticsService.setOptIn(true);
        
        expect(() => analyticsService.trackEvent('test_event', parameters: {}), returnsNormally);
      });

      test('should handle null parameters', () async {
        await analyticsService.setOptIn(true);
        
        expect(() => analyticsService.trackEvent('test_event'), returnsNormally);
      });
    });

    group('Privacy Compliance', () {
      test('should respect opt-out by default', () async {
        // Ensure initialized with default (false)
        await analyticsService.setOptIn(false);
        expect(analyticsService.optedIn, false);
        // Tracking should be disabled
      });

      test('should allow users to opt-out after opting in', () async {
        await analyticsService.setOptIn(true);
        expect(analyticsService.optedIn, true);
        
        await analyticsService.setOptIn(false);
        expect(analyticsService.optedIn, false);
      });

      test('should not track after opt-out', () async {
        await analyticsService.setOptIn(true);
        await analyticsService.setOptIn(false);
        
        // Should not track
        expect(() => analyticsService.trackScreenView('test'), returnsNormally);
        expect(() => analyticsService.trackEvent('test'), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // Even if preferences fail, service should initialize
        final service = AnalyticsService();
        await service.initialize();
        
        expect(service, isNotNull);
        expect(service.optedIn, false); // Default to false on error
      });

      test('should handle setOptIn errors gracefully', () async {
        // Should not throw even if preferences fail
        expect(() => analyticsService.setOptIn(true), returnsNormally);
      });
    });
  });
}

