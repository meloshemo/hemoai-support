import 'dart:async';
import 'dart:io' show HttpClient;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Professional network connectivity service with real-time monitoring
/// Handles network state changes and provides reliable connectivity checks
class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();
  
  List<ConnectivityResult> _currentStatus = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  List<ConnectivityResult> get currentStatus => _currentStatus;
  bool get isConnected => !_currentStatus.contains(ConnectivityResult.none);
  
  /// Initialize network monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get initial connectivity status
      _currentStatus = await _connectivity.checkConnectivity();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
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
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (_currentStatus.toString() != results.toString()) {
      _currentStatus = results;
      _logger.i('Network connectivity changed: $results');
      notifyListeners();
      
      // Log network type for debugging
      if (kDebugMode) {
        final primary = results.isNotEmpty ? results.first : ConnectivityResult.none;
        switch (primary) {
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
            _logger.d('Connected via ${primary.name}');
            break;
        }
      }
    }
  }
  
  /// Check current connectivity status
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_currentStatus.toString() != results.toString()) {
        _handleConnectivityChange(results);
      }
      return results;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return [ConnectivityResult.none];
    }
  }
  
  /// Check if device has internet connection (not just network interface)
  /// This performs an actual network request to verify internet access
  /// Note: For production, consider using a lightweight endpoint or DNS lookup
  Future<bool> hasInternetAccess({
    Duration timeout = const Duration(seconds: 5),
    List<String> testUrls = const [
      'https://www.google.com',
      'https://www.cloudflare.com',
    ],
  }) async {
    if (!isConnected) {
      return false;
    }
    
    // For web platform, connectivity check is usually sufficient
    if (kIsWeb) {
      return isConnected;
    }
    
    // For mobile platforms, perform actual network test
    // Note: HttpClient is imported from dart:io
    try {
      final client = HttpClient();
      client.connectionTimeout = timeout;
      
      for (final url in testUrls) {
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri).timeout(timeout);
          final response = await request.close().timeout(timeout);
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            client.close();
            return true;
          }
        } catch (e) {
          // Try next URL
          continue;
        } finally {
          client.close();
        }
      }
      
      return false;
    } catch (e) {
      _logger.w('Internet access check failed: $e');
      // Fallback: assume connected if we have network interface
      return isConnected;
    }
  }
  
  /// Get human-readable network status
  String getNetworkStatusText() {
    if (_currentStatus.isEmpty || _currentStatus.contains(ConnectivityResult.none)) {
      return 'No Connection';
    }
    
    final primary = _currentStatus.first;
    switch (primary) {
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

