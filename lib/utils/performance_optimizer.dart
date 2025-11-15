import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../services/cache_service.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';

/// Performance optimization utilities for HemoAI
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // Performance settings keys
  static const String _animationsEnabledKey = 'enable_animations';
  static const String _reduceMotionKey = 'reduce_motion';

  /// Check if animations are enabled
  Future<bool> areAnimationsEnabled() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getCustomSetting<bool>(_animationsEnabledKey) ?? true;
  }

  /// Set animations enabled/disabled
  Future<void> setAnimationsEnabled(bool enabled) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.saveCustomSettings(_animationsEnabledKey, enabled);
  }

  /// Check if motion should be reduced for accessibility
  Future<bool> shouldReduceMotion() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getCustomSetting<bool>(_reduceMotionKey) ?? false;
  }

  /// Set reduce motion preference
  Future<void> setReduceMotion(bool reduce) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.saveCustomSettings(_reduceMotionKey, reduce);
  }

  /// Clear all caches for better performance
  Future<void> clearAllCaches() async {
    try {
      // Clear HemoAI in-memory caches
      HemoAICache().clearAll();
      
      // Clear image cache if needed
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      if (kDebugMode) {
        debugPrint('🧹 All caches cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing caches: $e');
      }
      rethrow;
    }
  }

  /// Get cache size information
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final hemoCache = HemoAICache();
      
      final stats = hemoCache.getAllStats();
      final totalEntries = stats.values.fold<int>(0, (sum, s) => sum + s.size);

      return {
        'imageCacheCount': imageCache.currentSize,
        'imageCacheMaxSize': imageCache.maximumSize,
        'hemoaiCacheSize': totalEntries,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting cache info: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Optimize app performance based on device capabilities
  Future<void> optimizeForDevice() async {
    try {
      // Auto-disable animations on slower devices or when battery is low
      // This is a placeholder - in a real app, you'd check device specs
      final prefs = await PreferencesService.getInstance();
      
      // Example: disable animations in debug mode to speed up development
      if (kDebugMode) {
        final autoOptimize = prefs.getCustomSetting<bool>('auto_optimize') ?? false;
        if (autoOptimize) {
          await setAnimationsEnabled(false);
          if (kDebugMode) {
            debugPrint('🚀 Auto-optimization: Animations disabled for debug performance');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error optimizing for device: $e');
      }
    }
  }

  /// Preload critical data for smoother UX
  Future<void> preloadCriticalData() async {
    try {
      // Preload commonly used data to cache
      // This would typically load user preferences, recent hemogram data, etc.
      
      if (kDebugMode) {
        debugPrint('📊 Preloading critical data for better performance');
      }
      
      // Example: preload user preferences
      final prefs = await PreferencesService.getInstance();
      final _ = prefs.getUserInfo(); // Cache user info
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error preloading data: $e');
      }
    }
  }

  /// Get performance recommendations based on current state
  Future<List<String>> getPerformanceRecommendations() async {
    final recommendations = <String>[];
    final loc = LocalizationService();
    
    try {
      final cacheInfo = await getCacheInfo();
      final animationsEnabled = await areAnimationsEnabled();
      
      // Check cache size
      if (cacheInfo['hemoaiCacheSize'] != null && cacheInfo['hemoaiCacheSize'] > 100) {
        recommendations.add(loc.getString('performance_rec_clear_cache'));
      }
      
      // Check animations
      if (animationsEnabled && kDebugMode) {
        recommendations.add(loc.getString('performance_rec_disable_animations'));
      }
      
      // Platform-specific recommendations
      if (kIsWeb) {
        recommendations.add(loc.getString('performance_rec_use_chrome_edge'));
      }
      
      if (recommendations.isEmpty) {
        recommendations.add(loc.getString('performance_rec_optimized'));
      }
      
    } catch (e) {
      recommendations.add(loc.getStringWithParams('performance_rec_error_analyzing', {'error': e.toString()}));
    }
    
    return recommendations;
  }

  /// Apply recommended performance settings
  Future<void> applyRecommendedSettings() async {
    try {
      // Clear caches
      await clearAllCaches();
      
      // Optimize for current platform
      await optimizeForDevice();
      
      // Preload critical data
      await preloadCriticalData();
      
      if (kDebugMode) {
        debugPrint('✅ Recommended performance settings applied');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error applying recommended settings: $e');
      }
      rethrow;
    }
  }
}