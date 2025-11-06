import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// High-performance LRU (Least Recently Used) cache with memory limits.
/// Automatically evicts old data to prevent memory issues with large datasets.
class LRUCache<K, V> {
  final int _maxSize;
  final int _maxMemoryMB;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  int _currentMemoryBytes = 0;

  LRUCache({
    int maxSize = 1000,
    int maxMemoryMB = 50, // 50MB default limit
  }) : _maxSize = maxSize, _maxMemoryMB = maxMemoryMB;

  /// Get item from cache, updating its position
  V? get(K key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      // Move to end (most recently used)
      _cache[key] = entry;
      return entry.value;
    }
    return null;
  }

  /// Put item in cache with automatic eviction
  void put(K key, V value, {int? sizeBytes}) {
    // Remove existing entry if present
    final existing = _cache.remove(key);
    if (existing != null) {
      _currentMemoryBytes -= existing.sizeBytes;
    }

    final estimatedSize = sizeBytes ?? _estimateSize(value);
    final entry = _CacheEntry(value, estimatedSize);

    // Check memory limits
    while ((_currentMemoryBytes + estimatedSize) > (_maxMemoryMB * 1024 * 1024) && _cache.isNotEmpty) {
      _evictOldest();
    }

    // Check size limits
    while (_cache.length >= _maxSize && _cache.isNotEmpty) {
      _evictOldest();
    }

    _cache[key] = entry;
    _currentMemoryBytes += estimatedSize;
  }

  /// Remove item from cache
  V? remove(K key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentMemoryBytes -= entry.sizeBytes;
      return entry.value;
    }
    return null;
  }

  /// Clear all cached items
  void clear() {
    _cache.clear();
    _currentMemoryBytes = 0;
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
    size: _cache.length,
    maxSize: _maxSize,
    memoryMB: _currentMemoryBytes / (1024 * 1024),
    maxMemoryMB: _maxMemoryMB.toDouble(),
  );

  void _evictOldest() {
    if (_cache.isNotEmpty) {
      final oldest = _cache.keys.first;
      final entry = _cache.remove(oldest)!;
      _currentMemoryBytes -= entry.sizeBytes;
    }
  }

  int _estimateSize(V value) {
    if (value is String) {
      return value.length * 2; // UTF-16 encoding
    } else if (value is List) {
      return value.length * 8; // Rough estimate for list overhead
    } else if (value is Map) {
      return value.length * 16; // Rough estimate for map overhead
    }
    return 64; // Default estimate for unknown objects
  }
}

class _CacheEntry<V> {
  final V value;
  final int sizeBytes;

  _CacheEntry(this.value, this.sizeBytes);
}

class CacheStats {
  final int size;
  final int maxSize;
  final double memoryMB;
  final double maxMemoryMB;

  CacheStats({
    required this.size,
    required this.maxSize,
    required this.memoryMB,
    required this.maxMemoryMB,
  });

  double get utilizationPercent => (size / maxSize) * 100;
  double get memoryUtilizationPercent => (memoryMB / maxMemoryMB) * 100;
}

/// Specialized cache manager for HemoAI data types
class HemoAICache {
  static final HemoAICache _instance = HemoAICache._internal();
  factory HemoAICache() => _instance;
  HemoAICache._internal();

  final LRUCache<String, List<Map<String, dynamic>>> _hemogramCache = LRUCache(maxSize: 100, maxMemoryMB: 20);
  final LRUCache<String, Map<String, dynamic>> _analysisCache = LRUCache(maxSize: 200, maxMemoryMB: 10);
  final LRUCache<String, List<Map<String, dynamic>>> _familyCache = LRUCache(maxSize: 50, maxMemoryMB: 5);
  final LRUCache<String, Uint8List> _imageCache = LRUCache(maxSize: 20, maxMemoryMB: 100); // Larger for images

  // Hemogram data caching
  List<Map<String, dynamic>>? getHemogramHistory(int userId) {
    return _hemogramCache.get('hemogram_$userId');
  }

  void putHemogramHistory(int userId, List<Map<String, dynamic>> data) {
    final sizeBytes = data.length * 200; // Estimate based on typical hemogram record size
    _hemogramCache.put('hemogram_$userId', data, sizeBytes: sizeBytes);
  }

  // Analysis results caching
  Map<String, dynamic>? getAnalysisResult(String key) {
    return _analysisCache.get(key);
  }

  void putAnalysisResult(String key, Map<String, dynamic> result) {
    _analysisCache.put(key, result);
  }
  
  void remove(String key) {
    _hemogramCache.remove(key);
    _analysisCache.remove(key);
    _familyCache.remove(key);
    _imageCache.remove(key);
  }

  // Family data caching
  List<Map<String, dynamic>>? getFamilyMembers(int userId) {
    return _familyCache.get('family_$userId');
  }

  void clearFamilyMembers(int userId) {
    _familyCache.remove('family_$userId');
  }

  void putFamilyMembers(int userId, List<Map<String, dynamic>> members) {
    _familyCache.put('family_$userId', members);
  }

  // Image caching for OCR and reports
  Uint8List? getImage(String key) {
    return _imageCache.get(key);
  }

  void putImage(String key, Uint8List imageData) {
    _imageCache.put(key, imageData, sizeBytes: imageData.length);
  }

  /// Clear all caches
  void clearAll() {
    _hemogramCache.clear();
    _analysisCache.clear();
    _familyCache.clear();
    _imageCache.clear();
  }

  /// Get comprehensive cache statistics
  Map<String, CacheStats> getAllStats() {
    return {
      'hemogram': _hemogramCache.stats,
      'analysis': _analysisCache.stats,
      'family': _familyCache.stats,
      'images': _imageCache.stats,
    };
  }
}