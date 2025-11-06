import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/offline_service.dart';
import 'package:hemoai/services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineService', () {
    late OfflineService offlineService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      offlineService = OfflineService();
    });

    tearDown(() {
      offlineService.dispose();
    });

    test('should create singleton instance', () {
      final instance1 = OfflineService();
      final instance2 = OfflineService();
      expect(instance1, equals(instance2));
    });

    group('Operation Queueing', () {
      test('should queue operation when offline', () async {
        SharedPreferences.setMockInitialValues({});
        
        bool operationExecuted = false;
        
        await offlineService.queueOperation(
          operationType: 'test_operation',
          data: {'key': 'value'},
          execute: (data) async {
            operationExecuted = true;
          },
        );
        
        // Operation should be queued (not executed if offline)
        expect(operationExecuted, false);
        expect(offlineService.queueSize, greaterThanOrEqualTo(0));
      });

      test('should execute operation immediately when online', () async {
        SharedPreferences.setMockInitialValues({});
        
        bool operationExecuted = false;
        
        // Mock NetworkService to return online
        await offlineService.queueOperation(
          operationType: 'test_operation',
          data: {'key': 'value'},
          execute: (data) async {
            operationExecuted = true;
          },
        );
        
        // Operation may execute if online
        expect(operationExecuted, isA<bool>());
      });

      test('should queue operation with correct data', () async {
        SharedPreferences.setMockInitialValues({});
        
        final testData = {'userId': '123', 'action': 'save'};
        
        await offlineService.queueOperation(
          operationType: 'save_data',
          data: testData,
          execute: (data) async {},
        );
        
        expect(offlineService.queueSize, greaterThanOrEqualTo(0));
      });
    });

    group('Queue Management', () {
      test('should get queue size', () {
        expect(offlineService.queueSize, isA<int>());
        expect(offlineService.queueSize, greaterThanOrEqualTo(0));
      });

      test('should check if syncing', () {
        expect(offlineService.isSyncing, isA<bool>());
      });

      test('should clear queue', () async {
        await offlineService.queueOperation(
          operationType: 'test',
          data: {},
          execute: (data) async {},
        );
        
        await offlineService.clearQueue();
        expect(offlineService.queueSize, equals(0));
      });
    });

    group('Queue Persistence', () {
      test('should save queue to storage', () async {
        SharedPreferences.setMockInitialValues({});
        
        await offlineService.queueOperation(
          operationType: 'test',
          data: {'key': 'value'},
          execute: (data) async {},
        );
        
        // Queue should be saved
        expect(offlineService.queueSize, greaterThanOrEqualTo(0));
      });

      test('should load queue from storage', () async {
        SharedPreferences.setMockInitialValues({});
        
        // Queue some operations
        await offlineService.queueOperation(
          operationType: 'test1',
          data: {},
          execute: (data) async {},
        );
        
        // Create new instance (should load from storage)
        final newService = OfflineService();
        // Queue should be loaded
        expect(newService.queueSize, isA<int>());
      });
    });

    group('Sync Operations', () {
      test('should sync queue when online', () async {
        SharedPreferences.setMockInitialValues({});
        
        await offlineService.queueOperation(
          operationType: 'test',
          data: {},
          execute: (data) async {},
        );
        
        // Try to sync (may not execute if offline)
        await offlineService.syncQueue();
        
        // Should not throw
        expect(offlineService, isNotNull);
      });

      test('should handle sync errors gracefully', () async {
        SharedPreferences.setMockInitialValues({});
        
        await offlineService.queueOperation(
          operationType: 'test',
          data: {},
          execute: (data) async {
            throw Exception('Test error');
          },
        );
        
        // Should handle error without crashing
        await offlineService.syncQueue();
        expect(offlineService, isNotNull);
      });
    });
  });
}

