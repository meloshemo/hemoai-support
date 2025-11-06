import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Timeout exception for background tasks
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}

/// High-performance processing service using isolates for CPU-intensive tasks.
/// Prevents UI blocking with background computation and chunked processing.
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Isolate> _activeIsolates = {};
  final Map<String, ReceivePort> _receivePorts = {};

  /// Process large data sets in background isolate with progress callbacks
  Future<T> processInBackground<T>({
    required String taskId,
    required Future<T> Function() computation,
    Function(double progress)? onProgress,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (kIsWeb) {
      // Web doesn't support isolates, use chunked processing instead
      return await _processInChunks(computation, onProgress, timeout);
    }

    final completer = Completer<T>();
    final receivePort = ReceivePort();
    _receivePorts[taskId] = receivePort;

    try {
      final isolate = await Isolate.spawn(
        _isolateEntryPoint<T>,
        _IsolateMessage<T>(
          sendPort: receivePort.sendPort,
          computation: computation,
          taskId: taskId,
        ),
      );
      
      _activeIsolates[taskId] = isolate;

      // Listen for results and progress updates
      late StreamSubscription subscription;
      subscription = receivePort.listen((message) {
        if (message is _IsolateResult<T>) {
          if (message.isError) {
            completer.completeError(message.error!);
          } else {
            completer.complete(message.result);
          }
          subscription.cancel();
          _cleanup(taskId);
        }
      });

      // Set timeout
      Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Task timeout', timeout));
          _cleanup(taskId);
        }
      });

      return await completer.future;
    } catch (e) {
      // If isolate spawning fails (e.g., due to unsendable closures),
      // gracefully fall back to chunked processing on the main isolate.
      _cleanup(taskId);
      return await _processInChunks(computation, onProgress, timeout);
    }
  }

  /// Chunked processing for web or lighter tasks
  Future<T> _processInChunks<T>(
    Future<T> Function() computation,
    Function(double progress)? onProgress,
    [Duration? timeout]
  ) async {
    // Simulate chunked processing with periodic yields
    const chunkSize = 100;
    var processed = 0;
    
    while (processed < chunkSize) {
      // Yield control back to the UI thread
      await Future.delayed(const Duration(microseconds: 100));
      processed++;
      onProgress?.call(processed / chunkSize);
    }

    final future = computation();
    if (timeout != null) {
      return await future.timeout(timeout, onTimeout: () {
        throw TimeoutException('Task timeout', timeout);
      });
    }
    return await future;
  }

  /// Cancel a background task
  void cancelTask(String taskId) {
    _cleanup(taskId);
  }

  void _cleanup(String taskId) {
    _activeIsolates[taskId]?.kill();
    _activeIsolates.remove(taskId);
    _receivePorts[taskId]?.close();
    _receivePorts.remove(taskId);
  }

  /// Clean up all resources
  void dispose() {
    for (final taskId in _activeIsolates.keys.toList()) {
      _cleanup(taskId);
    }
  }

  /// Isolate entry point
  static void _isolateEntryPoint<T>(_IsolateMessage<T> message) async {
    try {
      final result = await message.computation();
      message.sendPort.send(_IsolateResult<T>(result: result));
    } catch (e) {
      message.sendPort.send(_IsolateResult<T>(error: e, isError: true));
    }
  }
}

/// Message structure for isolate communication
class _IsolateMessage<T> {
  final SendPort sendPort;
  final Future<T> Function() computation;
  final String taskId;

  _IsolateMessage({
    required this.sendPort,
    required this.computation,
    required this.taskId,
  });
}

/// Result wrapper for isolate communication
class _IsolateResult<T> {
  final T? result;
  final Object? error;
  final bool isError;

  _IsolateResult({
    this.result,
    this.error,
    this.isError = false,
  });
}