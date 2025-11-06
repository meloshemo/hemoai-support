import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Professional deep linking handler
/// Handles app links, custom URL schemes, and universal links
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final Logger _logger = Logger();

  /// Parse and route deep link
  /// Supports formats:
  /// - hemoai://app/analysis
  /// - hemoai://app/family_panel?memberId=123
  /// - https://hemoai.app/analysis
  /// - https://www.hemoai.app/family_panel?memberId=123
  Future<void> handleDeepLink(
    String link, {
    required BuildContext context,
  }) async {
    try {
      _logger.i('Handling deep link: $link');

      // Parse URL
      final uri = Uri.parse(link);
      
      String? route;
      Map<String, dynamic>? arguments;

      // Handle custom scheme (hemoai://)
      if (uri.scheme == 'hemoai' && uri.host == 'app') {
        route = _parseCustomScheme(uri);
        arguments = _parseQueryParameters(uri);
      }
      // Handle universal links (https://)
      else if (uri.scheme == 'https' && 
               (uri.host == 'hemoai.app' || uri.host == 'www.hemoai.app')) {
        route = _parseUniversalLink(uri);
        arguments = _parseQueryParameters(uri);
      }
      // Handle legacy format
      else if (link.startsWith('/')) {
        route = link;
      }

      if (route != null) {
        await _navigateToRoute(context, route, arguments);
      } else {
        _logger.w('Unknown deep link format: $link');
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling deep link: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// Parse custom scheme route
  String? _parseCustomScheme(Uri uri) {
    final path = uri.path;
    if (path.isEmpty || path == '/') {
      return '/dashboard';
    }

    // Remove leading slash
    final route = path.startsWith('/') ? path : '/$path';
    
    // Map common routes
    return _mapRoute(route);
  }

  /// Parse universal link route
  String? _parseUniversalLink(Uri uri) {
    final path = uri.path;
    if (path.isEmpty || path == '/') {
      return '/dashboard';
    }

    // Remove leading slash
    final route = path.startsWith('/') ? path : '/$path';
    
    // Map common routes
    return _mapRoute(route);
  }

  /// Map route paths to app routes
  String _mapRoute(String path) {
    // Remove query parameters if present
    final cleanPath = path.split('?').first;

    // Direct route mapping
    final routeMap = {
      '/dashboard': '/dashboard',
      '/analysis': '/analysis',
      '/family': '/family_panel',
      '/family_panel': '/family_panel',
      '/reminders': '/reminders',
      '/diet': '/diet_program',
      '/diet_program': '/diet_program',
      '/settings': '/settings',
      '/premium': '/premium',
      '/notifications': '/notifications',
      '/profile': '/personal_info',
      '/personal_info': '/personal_info',
      '/hemogram': '/hemogram_entry',
      '/hemogram_entry': '/hemogram_entry',
      '/data_import': '/data_import',
      '/challenges': '/challenges',
      '/stats': '/stats',
      '/about': '/about',
    };

    return routeMap[cleanPath.toLowerCase()] ?? cleanPath;
  }

  /// Parse query parameters
  Map<String, dynamic>? _parseQueryParameters(Uri uri) {
    if (uri.queryParameters.isEmpty) {
      return null;
    }

    final arguments = <String, dynamic>{};
    
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Try to parse as number
      final numValue = num.tryParse(value);
      if (numValue != null) {
        arguments[key] = numValue;
      } else {
        arguments[key] = value;
      }
    }

    return arguments.isEmpty ? null : arguments;
  }

  /// Navigate to route with arguments
  Future<void> _navigateToRoute(
    BuildContext context,
    String route,
    Map<String, dynamic>? arguments,
  ) async {
    if (!context.mounted) return;

    try {
      // Handle routes with arguments
      if (arguments != null && arguments.isNotEmpty) {
        if (route == '/family_member_detail') {
          Navigator.pushNamed(context, route, arguments: arguments);
        } else if (route == '/analysis' && arguments.containsKey('values')) {
          Navigator.pushNamed(context, route, arguments: arguments['values']);
        } else {
          // For other routes, pass arguments as query parameters
          Navigator.pushNamed(context, route, arguments: arguments);
        }
      } else {
        Navigator.pushNamed(context, route);
      }

      _logger.i('Navigated to route: $route');
    } catch (e) {
      _logger.e('Error navigating to route $route: $e');
      // Fallback to dashboard
      if (context.mounted) {
        Navigator.pushNamed(context, '/dashboard');
      }
    }
  }

  /// Generate deep link URL
  String generateDeepLink({
    required String route,
    Map<String, dynamic>? parameters,
  }) {
    final uri = Uri(
      scheme: 'hemoai',
      host: 'app',
      path: route.startsWith('/') ? route.substring(1) : route,
      queryParameters: parameters?.map((key, value) => MapEntry(key, value.toString())),
    );
    return uri.toString();
  }

  /// Generate universal link URL
  String generateUniversalLink({
    required String route,
    Map<String, dynamic>? parameters,
  }) {
    final uri = Uri(
      scheme: 'https',
      host: 'hemoai.app',
      path: route.startsWith('/') ? route.substring(1) : route,
      queryParameters: parameters?.map((key, value) => MapEntry(key, value.toString())),
    );
    return uri.toString();
  }
}

/// Extension for easy deep link handling in widgets
extension DeepLinkExtension on BuildContext {
  /// Handle deep link from this context
  Future<void> handleDeepLink(String link) async {
    await DeepLinkHandler().handleDeepLink(link, context: this);
  }
}

