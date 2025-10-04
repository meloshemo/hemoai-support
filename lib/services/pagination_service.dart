import 'package:flutter/foundation.dart';
import 'cache_service.dart';

/// Pagination controller for efficient handling of large datasets.
/// Implements virtual scrolling and lazy loading patterns.
class PaginationController<T> extends ChangeNotifier {
  final Future<List<T>> Function(int offset, int limit) _dataFetcher;
  final String _cacheKey;
  final int _pageSize;
  
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  String? _error;
  int _currentPage = 0;

  PaginationController({
    required Future<List<T>> Function(int offset, int limit) dataFetcher,
    required String cacheKey,
    int pageSize = 50,
  }) : _dataFetcher = dataFetcher,
       _cacheKey = cacheKey,
       _pageSize = pageSize;

  // Getters
  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  String? get error => _error;
  int get totalItems => _items.length;
  bool get isEmpty => _items.isEmpty && !_isLoading;

  /// Load initial data
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _items.clear();
    notifyListeners();

    try {
      final data = await _dataFetcher(0, _pageSize);
      _items.addAll(data);
      _hasMoreData = data.length == _pageSize;
      _currentPage = 1;
      
      // Cache the first page
      HemoAICache().putAnalysisResult('${_cacheKey}_page_0', {
        'data': data.map((item) => _serializeItem(item)).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('Pagination error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final offset = _currentPage * _pageSize;
      
      // Check cache first
      final cached = HemoAICache().getAnalysisResult('${_cacheKey}_page_$_currentPage');
      if (cached != null && _isCacheValid(cached)) {
        final cachedData = (cached['data'] as List)
            .map((item) => _deserializeItem(item))
            .cast<T>()
            .toList();
        _items.addAll(cachedData);
        _hasMoreData = cachedData.length == _pageSize;
      } else {
        // Fetch from source
        final data = await _dataFetcher(offset, _pageSize);
        _items.addAll(data);
        _hasMoreData = data.length == _pageSize;
        
        // Cache the page
        HemoAICache().putAnalysisResult('${_cacheKey}_page_$_currentPage', {
          'data': data.map((item) => _serializeItem(item)).toList(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      _currentPage++;
    } catch (e) {
      _error = e.toString();
      debugPrint('Pagination error loading more data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    // Clear cache for this key
    final cache = HemoAICache();
    for (int i = 0; i < _currentPage; i++) {
      cache.getAnalysisResult('${_cacheKey}_page_$i');
    }
    
    _hasMoreData = true;
    await loadInitial();
  }

  /// Insert item at beginning (for new data)
  void insertItem(T item, {bool updateCache = true}) {
    _items.insert(0, item);
    if (updateCache) {
      _invalidateCache();
    }
    notifyListeners();
  }

  /// Remove item by predicate
  void removeWhere(bool Function(T) test, {bool updateCache = true}) {
    _items.removeWhere(test);
    if (updateCache) {
      _invalidateCache();
    }
    notifyListeners();
  }

  /// Update item by predicate
  void updateWhere(bool Function(T) test, T Function(T) updater, {bool updateCache = true}) {
    for (int i = 0; i < _items.length; i++) {
      if (test(_items[i])) {
        _items[i] = updater(_items[i]);
      }
    }
    if (updateCache) {
      _invalidateCache();
    }
    notifyListeners();
  }

  void _invalidateCache() {
    final cache = HemoAICache();
    for (int i = 0; i < _currentPage; i++) {
      cache.remove('${_cacheKey}_page_$i');
    }
  }

  bool _isCacheValid(Map<String, dynamic> cached) {
    final timestamp = cached['timestamp'] as int?;
    if (timestamp == null) return false;
    
    const maxAge = Duration(minutes: 10); // Cache valid for 10 minutes
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age < maxAge.inMilliseconds;
  }

  // Override these methods in subclasses for type-specific serialization
  Map<String, dynamic> _serializeItem(T item) {
    if (item is Map<String, dynamic>) {
      return item;
    }
    return {'data': item.toString()};
  }

  T _deserializeItem(dynamic item) {
    return item as T;
  }

  // No additional resources to dispose
}

/// Specialized pagination controllers for HemoAI data types
class HemogramPaginationController extends PaginationController<Map<String, dynamic>> {
  HemogramPaginationController({
    required super.dataFetcher,
    required int userId,
  }) : super(
          cacheKey: 'hemogram_pagination_$userId',
          pageSize: 20, // Smaller pages for detailed hemogram data
        );

  @override
  Map<String, dynamic> _serializeItem(Map<String, dynamic> item) => item;

  @override
  Map<String, dynamic> _deserializeItem(dynamic item) => item as Map<String, dynamic>;
}

class FamilyMemberPaginationController extends PaginationController<Map<String, dynamic>> {
  FamilyMemberPaginationController({
    required super.dataFetcher,
    required int userId,
  }) : super(
          cacheKey: 'family_pagination_$userId',
          pageSize: 10, // Small pages for family members
        );

  @override
  Map<String, dynamic> _serializeItem(Map<String, dynamic> item) => item;

  @override
  Map<String, dynamic> _deserializeItem(dynamic item) => item as Map<String, dynamic>;
}

/// Infinite scroll widget helper
class InfiniteScrollController {
  final PaginationController controller;
  final double threshold;

  InfiniteScrollController({
    required this.controller,
    this.threshold = 200.0, // Load more when 200px from bottom
  });

  /// Check if we should load more data based on scroll position
  bool shouldLoadMore(double scrollOffset, double maxScrollExtent) {
    if (!controller.hasMoreData || controller.isLoading) return false;
    return scrollOffset >= (maxScrollExtent - threshold);
  }

  /// Handle scroll events
  void handleScroll(double scrollOffset, double maxScrollExtent) {
    if (shouldLoadMore(scrollOffset, maxScrollExtent)) {
      controller.loadMore();
    }
  }
}