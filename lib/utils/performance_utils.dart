import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Professional performance optimization utilities
/// Provides tools for optimizing app performance

class PerformanceUtils {
  /// Debounce function to limit function calls
  static Function debounce(Function func, [Duration delay = const Duration(milliseconds: 500)]) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => func());
    };
  }

  /// Throttle function to limit function calls
  static Function throttle(Function func, [Duration delay = const Duration(milliseconds: 300)]) {
    Timer? timer;
    bool isThrottled = false;
    return () {
      if (!isThrottled) {
        func();
        isThrottled = true;
        timer = Timer(delay, () {
          isThrottled = false;
        });
      }
    };
  }

  /// Check if should use reduced motion for animations
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Use frame callback for heavy operations
  static void scheduleFrameCallback(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Optimize image loading
  static Widget optimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width != null ? width.toInt() : null,
      cacheHeight: height != null ? height.toInt() : null,
      errorBuilder: (context, error, stackTrace) {
        return placeholder != null
            ? Image.asset(placeholder, width: width, height: height, fit: fit)
            : Icon(Icons.error, size: width ?? height ?? 24);
      },
    );
  }

  /// Lazy load list with pagination
  static List<T> lazyLoadList<T>({
    required List<T> allItems,
    required int currentPage,
    int itemsPerPage = 20,
  }) {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, allItems.length);
    return allItems.sublist(startIndex, endIndex);
  }

  /// Memoize expensive computations
  static final Map<String, dynamic> _memoCache = {};

  static T? memoize<T>(String key, T Function() computation) {
    if (_memoCache.containsKey(key)) {
      return _memoCache[key] as T?;
    }
    final result = computation();
    _memoCache[key] = result;
    return result;
  }

  /// Clear memo cache
  static void clearMemoCache() {
    _memoCache.clear();
  }

  /// Optimize list rendering
  static Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Optimize grid rendering
  static Widget optimizedGridView({
    required List<Widget> children,
    required int crossAxisCount,
    double crossAxisSpacing = 8,
    double mainAxisSpacing = 8,
    ScrollController? controller,
  }) {
    return GridView.builder(
      controller: controller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Extension for list performance optimization
extension ListPerformanceExtension<T> on List<T> {
  /// Get paginated subset
  List<T> paginated(int page, int itemsPerPage) {
    final start = page * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, length);
    return sublist(start, end);
  }
}

/// Widget for lazy loading images
class LazyLoadImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyLoadImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }
}

