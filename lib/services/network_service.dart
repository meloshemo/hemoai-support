import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

/// Professional network connectivity service with real-time monitoring
/// Handles network state changes and provides reliable connectivity checks
class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();
  static const List<ConnectivityResult> _statusPriority = <ConnectivityResult>[
    ConnectivityResult.wifi,
    ConnectivityResult.ethernet,
    ConnectivityResult.mobile,
    ConnectivityResult.bluetooth,
    ConnectivityResult.vpn,
    ConnectivityResult.other,
    ConnectivityResult.none,
  ];

  ConnectivityResult _currentStatus = ConnectivityResult.none;
  StreamSubscription<dynamic>? _connectivitySubscription;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  ConnectivityResult get currentStatus => _currentStatus;
  bool get isConnected => _currentStatus != ConnectivityResult.none;

  /// Initialize network monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get initial connectivity status
      final initialResults = await _connectivity.checkConnectivity();
      _currentStatus = _normalizeStatus(initialResults);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (dynamic value) {
          final status = _normalizeStatus(value);
          _handleConnectivityChange(status);
        },
        onError: (error) {
          _logger.e('Connectivity stream error: $error');
        },
      );

      _isInitialized = true;
      _logger.i('NetworkService initialized. Current status: $_currentStatus');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize NetworkService: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  ConnectivityResult _reduceResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityResult.none;
    }

    for (final status in _statusPriority) {
      if (results.contains(status)) {
        return status;
      }
    }
    return ConnectivityResult.none;
  }

  ConnectivityResult _normalizeStatus(dynamic value) {
    if (value is ConnectivityResult) {
      return value;
    }
    if (value is List<ConnectivityResult>) {
      return _reduceResults(value);
    }
    return ConnectivityResult.none;
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (_currentStatus != result) {
      _currentStatus = result;
      _logger.i('Network connectivity changed: $result');
      notifyListeners();

      // Log network type for debugging
      if (kDebugMode) {
        switch (_currentStatus) {
          case ConnectivityResult.wifi:
            _logger.d('Connected via WiFi');
            break;
          case ConnectivityResult.mobile:
            _logger.d('Connected via Mobile Data');
            break;
          case ConnectivityResult.ethernet:
            _logger.d('Connected via Ethernet');
            break;
          case ConnectivityResult.none:
            _logger.w('No internet connection');
            break;
          case ConnectivityResult.bluetooth:
          case ConnectivityResult.vpn:
          case ConnectivityResult.other:
            _logger.d('Connected via ${_currentStatus.name}');
            break;
        }
      }
    }
  }

  /// Check current connectivity status
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final status = _normalizeStatus(results);
      if (_currentStatus != status) {
        _handleConnectivityChange(status);
      }
      return status;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return ConnectivityResult.none;
    }
  }

  /// Check if device has internet connection (not just network interface)
  /// This performs an actual network request to verify internet access
  /// Note: For production, consider using a lightweight endpoint or DNS lookup
  Future<bool> hasInternetAccess({
    Duration timeout = const Duration(seconds: 5),
    List<String> testUrls = const [
      'https://www.gstatic.com/generate_204',
      'https://1.1.1.1',
    ],
  }) async {
    if (!isConnected) {
      return false;
    }

    // For web platform, connectivity check is usually sufficient
    if (kIsWeb) {
      return isConnected;
    }

    // For non-web platforms, perform a lightweight HTTP GET
    try {
      final client = http.Client();
      for (final url in testUrls) {
        try {
          final uri = Uri.parse(url);
          final response = await client.get(uri).timeout(timeout);
          if (response.statusCode >= 200 && response.statusCode < 400) {
            client.close();
            return true;
          }
        } catch (_) {
          // Try next URL
          continue;
        }
      }
      client.close();
      return false;
    } catch (e) {
      _logger.w('Internet access check failed: $e');
      // Fallback: assume connected if we have network interface
      return isConnected;
    }
  }

  /// Get human-readable network status
  String getNetworkStatusText() {
    if (_currentStatus == ConnectivityResult.none) {
      return 'No Connection';
    }

    switch (_currentStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'No Connection';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }
}

/// Extension for easy network-aware operations
extension NetworkAwareFuture<T> on Future<T> {
  /// Execute only if network is available, otherwise throw NetworkException
  Future<T> requireNetwork() async {
    final networkService = NetworkService();
    if (!networkService.isInitialized) {
      await networkService.initialize();
    }

    if (!networkService.isConnected) {
      throw NetworkException('No network connection available');
    }

    return this;
  }

  /// Execute with network check, returning null if offline
  Future<T?> withNetworkFallback() async {
    try {
      return await requireNetwork();
    } on NetworkException {
      return null;
    }
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
