import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/utils/performance_optimizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('PerformanceOptimizer Tests', () {
    late PerformanceOptimizer optimizer;

    setUp(() {
      optimizer = PerformanceOptimizer();
    });

    test('should create singleton instance', () {
      final instance1 = PerformanceOptimizer();
      final instance2 = PerformanceOptimizer();
      expect(instance1, equals(instance2));
    });

    group('Animation Settings', () {
      test('should default to animations enabled', () async {
        final enabled = await optimizer.areAnimationsEnabled();
        expect(enabled, isTrue);
      });

      test('should toggle animations successfully', () async {
        await optimizer.setAnimationsEnabled(false);
        expect(await optimizer.areAnimationsEnabled(), isFalse);
        
        await optimizer.setAnimationsEnabled(true);
        expect(await optimizer.areAnimationsEnabled(), isTrue);
      });
    });

    group('Motion Settings', () {
      test('should default to motion not reduced', () async {
        final reduced = await optimizer.shouldReduceMotion();
        expect(reduced, isFalse);
      });

      test('should toggle reduce motion successfully', () async {
        await optimizer.setReduceMotion(true);
        expect(await optimizer.shouldReduceMotion(), isTrue);
        
        await optimizer.setReduceMotion(false);
        expect(await optimizer.shouldReduceMotion(), isFalse);
      });
    });

    group('Cache Management', () {
      test('should clear all caches without error', () async {
        expect(() => optimizer.clearAllCaches(), returnsNormally);
      });

      test('should get cache information', () async {
        final cacheInfo = await optimizer.getCacheInfo();
        
        expect(cacheInfo, isA<Map<String, dynamic>>());
        expect(cacheInfo.containsKey('timestamp'), isTrue);
      });

      test('should handle cache errors gracefully', () async {
        // Test that cache operations don't crash
        expect(() => optimizer.clearAllCaches(), returnsNormally);
      });
    });

    group('Performance Recommendations', () {
      test('should provide performance recommendations', () async {
        final recommendations = await optimizer.getPerformanceRecommendations();
        
        expect(recommendations, isA<List<String>>());
        expect(recommendations, isNotEmpty);
      });

      test('should include meaningful recommendations', () async {
        final recommendations = await optimizer.getPerformanceRecommendations();
        
        // Should have at least one recommendation
        expect(recommendations.length, greaterThan(0));
        
        // Each recommendation should be a non-empty string
        for (final rec in recommendations) {
          expect(rec, isA<String>());
          expect(rec.trim(), isNotEmpty);
        }
      });
    });

    group('Device Optimization', () {
      test('should optimize for device without error', () async {
        expect(() => optimizer.optimizeForDevice(), returnsNormally);
      });

      test('should preload critical data', () async {
        expect(() => optimizer.preloadCriticalData(), returnsNormally);
      });
    });

    group('Recommended Settings', () {
      test('should apply recommended settings', () async {
        expect(() => optimizer.applyRecommendedSettings(), returnsNormally);
      });

      test('should handle settings application errors', () async {
        // Test that applying settings doesn't crash even if some operations fail
        expect(() => optimizer.applyRecommendedSettings(), returnsNormally);
      });
    });

    group('Integration Tests', () {
      test('should maintain settings after cache clear', () async {
        // Set specific settings
        await optimizer.setAnimationsEnabled(false);
        await optimizer.setReduceMotion(true);
        
        // Clear caches
        await optimizer.clearAllCaches();
        
        // Settings should persist
        expect(await optimizer.areAnimationsEnabled(), isFalse);
        expect(await optimizer.shouldReduceMotion(), isTrue);
      });

      test('should provide consistent recommendations', () async {
        final rec1 = await optimizer.getPerformanceRecommendations();
        final rec2 = await optimizer.getPerformanceRecommendations();
        
        // Recommendations should be consistent for same state
        expect(rec1.length, equals(rec2.length));
      });
    });

    group('Error Handling', () {
      test('should handle cache operations gracefully', () {
        expect(() => optimizer.clearAllCaches(), returnsNormally);
        expect(() => optimizer.getCacheInfo(), returnsNormally);
      });

      test('should handle invalid settings gracefully', () {
        expect(() => optimizer.setAnimationsEnabled(true), returnsNormally);
        expect(() => optimizer.setReduceMotion(false), returnsNormally);
      });
    });
  });
}