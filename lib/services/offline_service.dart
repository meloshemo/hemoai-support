import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'network_service.dart';

/// Offline-first service for handling offline operations
/// Queues operations when offline and syncs when online
class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Logger _logger = Logger();
  final List<QueuedOperation> _operationQueue = [];
  bool _isSyncing = false;
  static const String _queueKey = 'offline_operation_queue';

  /// Since this is a singleton used across tests, override dispose to avoid
  /// marking the ChangeNotifier as disposed between tests. We'll still clear
  /// transient state but intentionally do not call super.dispose().
  @override
  void dispose() {
    _isSyncing = false;
    super.dispose();
  }

  /// Queue an operation for later execution
  Future<void> queueOperation({
    required String operationType,
    required Map<String, dynamic> data,
    required Future<void> Function(Map<String, dynamic>) execute,
  }) async {
    final networkService = NetworkService();
    if (!networkService.isInitialized) {
      try {
        await networkService.initialize();
      } catch (_) {
        // Ignore initialization failures in test/headless environments
      }
    }

    // If online, execute immediately
    if (networkService.isConnected) {
      try {
        await execute(data);
        return;
      } catch (e) {
        _logger.w('Operation failed, queueing for retry: $e');
        // Fall through to queue
      }
    }

    // Queue for later
    final operation = QueuedOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: operationType,
      data: data,
      timestamp: DateTime.now(),
      execute: execute,
    );

    _operationQueue.add(operation);
    await _saveQueue();
    notifyListeners();

    _logger.i('Operation queued: $operationType (Queue size: ${_operationQueue.length})');
  }

  /// Sync queued operations when online
  Future<void> syncQueue() async {
    if (_isSyncing || _operationQueue.isEmpty) return;

    final networkService = NetworkService();
    if (!networkService.isInitialized) {
      try {
        await networkService.initialize();
      } catch (_) {
        // Ignore in tests
      }
    }

    if (!networkService.isConnected) {
      _logger.d('Cannot sync: offline');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final operationsToSync = List<QueuedOperation>.from(_operationQueue);
      final failedOperations = <QueuedOperation>[];

      for (final operation in operationsToSync) {
        try {
          await operation.execute(operation.data);
          _operationQueue.remove(operation);
          _logger.i('Synced operation: ${operation.type}');
        } catch (e) {
          _logger.e('Failed to sync operation ${operation.type}: $e');
          failedOperations.add(operation);
        }
      }

      // Remove failed operations if they're too old (24 hours)
      final now = DateTime.now();
      _operationQueue.removeWhere((op) {
        if (failedOperations.contains(op)) {
          final age = now.difference(op.timestamp);
          if (age.inHours > 24) {
            _logger.w('Removing stale operation: ${op.type}');
            return true;
          }
        }
        return false;
      });

      await _saveQueue();
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Load queue from storage
  Future<void> loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson == null) return;

      // Note: In production, you'd deserialize the queue
      // For now, we'll just clear old queue and start fresh
      _operationQueue.clear();
      await _saveQueue();

      _logger.i('Loaded operation queue (${_operationQueue.length} operations)');
    } catch (e) {
      _logger.e('Failed to load queue: $e');
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Note: In production, serialize queue properly
      // For now, just store operation count
      await prefs.setInt('${_queueKey}_count', _operationQueue.length);
    } catch (e) {
      _logger.e('Failed to save queue: $e');
    }
  }

  /// Clear queue
  Future<void> clearQueue() async {
    _operationQueue.clear();
    await _saveQueue();
    notifyListeners();
  }

  /// Get queue status
  int get queueSize => _operationQueue.length;
  bool get isSyncing => _isSyncing;
  bool get hasQueuedOperations => _operationQueue.isNotEmpty;
}

/// Queued operation model
class QueuedOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Future<void> Function(Map<String, dynamic>) execute;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.execute,
  });
}

