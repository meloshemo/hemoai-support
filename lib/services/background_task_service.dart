import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:logger/logger.dart';
import 'network_service.dart';
import 'offline_service.dart';
import 'cloud_sync_service.dart';

/// Professional background task service
/// Handles background sync, notifications, and scheduled tasks
class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  final Logger _logger = Logger();
  static const String _syncTaskName = 'backgroundSync';
  static const String _notificationTaskName = 'backgroundNotification';

  /// Initialize background tasks
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      _logger.i('BackgroundTaskService initialized');
    } catch (e) {
      _logger.e('Failed to initialize BackgroundTaskService: $e');
    }
  }

  /// Register periodic background sync
  Future<void> registerPeriodicSync({
    Duration frequency = const Duration(hours: 6),
  }) async {
    try {
      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      _logger.i('Periodic sync registered: ${frequency.inHours} hours');
    } catch (e) {
      _logger.e('Failed to register periodic sync: $e');
    }
  }

  /// Register one-time background task
  Future<void> registerOneTimeTask({
    required String taskName,
    required Duration delay,
    Map<String, dynamic>? inputData,
  }) async {
    try {
      await Workmanager().registerOneOffTask(
        taskName,
        taskName,
        initialDelay: delay,
        inputData: inputData,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _logger.i('One-time task registered: $taskName');
    } catch (e) {
      _logger.e('Failed to register one-time task: $e');
    }
  }

  /// Cancel background task
  Future<void> cancelTask(String taskName) async {
    try {
      await Workmanager().cancelByUniqueName(taskName);
      _logger.i('Task cancelled: $taskName');
    } catch (e) {
      _logger.e('Failed to cancel task: $taskName');
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.i('All tasks cancelled');
    } catch (e) {
      _logger.e('Failed to cancel all tasks');
    }
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger();
    try {
      switch (task) {
        case 'backgroundSync':
          return await _performBackgroundSync();
        case 'backgroundNotification':
          return await _performBackgroundNotification();
        default:
          logger.w('Unknown background task: $task');
          return false;
      }
    } catch (e) {
      logger.e('Background task error: $e');
      return false;
    }
  });
}

/// Perform background sync
Future<bool> _performBackgroundSync() async {
  final logger = Logger();
  try {
    final networkService = NetworkService();
    if (!networkService.isInitialized) {
      await networkService.initialize();
    }

    if (!networkService.isConnected) {
      logger.d('Background sync skipped: offline');
      return false;
    }

    // Sync offline queue
    final offlineService = OfflineService();
    await offlineService.syncQueue();

    // Sync cloud data
    final cloudSyncService = CloudSyncService();
    // Note: Requires user ID from secure storage
    // await cloudSyncService.syncTables(userId: userId);

    logger.i('Background sync completed');
    return true;
  } catch (e) {
    logger.e('Background sync failed: $e');
    return false;
  }
}

/// Perform background notification
Future<bool> _performBackgroundNotification() async {
  final logger = Logger();
  try {
    // Schedule notifications logic here
    // This would check for reminders, medications, etc.
    logger.i('Background notification completed');
    return true;
  } catch (e) {
    logger.e('Background notification failed: $e');
    return false;
  }
}

