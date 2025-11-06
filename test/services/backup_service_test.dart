import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService', () {
    late BackupService backupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backupService = BackupService();
    });

    test('should create singleton instance', () {
      final instance1 = BackupService();
      final instance2 = BackupService();
      expect(instance1, equals(instance2));
    });

    group('Export All', () {
      test('should export data as JSON bytes', () async {
        final bytes = await backupService.exportAll();
        
        expect(bytes, isNotEmpty);
        expect(bytes, isA<List<int>>());
      });

      test('should export valid JSON structure', () async {
        final bytes = await backupService.exportAll();
        final text = utf8.decode(bytes);
        final decoded = jsonDecode(text);
        
        expect(decoded, isA<Map<String, dynamic>>());
        expect(decoded.containsKey('schema'), true);
        expect(decoded.containsKey('exported_at'), true);
        expect(decoded.containsKey('platform'), true);
        expect(decoded.containsKey('data'), true);
      });

      test('should include schema version', () async {
        final bytes = await backupService.exportAll();
        final text = utf8.decode(bytes);
        final decoded = jsonDecode(text);
        
        expect(decoded['schema'], isA<int>());
        expect(decoded['schema'], greaterThanOrEqualTo(1));
      });

      test('should include export timestamp', () async {
        final bytes = await backupService.exportAll();
        final text = utf8.decode(bytes);
        final decoded = jsonDecode(text);
        
        expect(decoded['exported_at'], isA<String>());
        // Should be valid ISO8601
        expect(() => DateTime.parse(decoded['exported_at']), returnsNormally);
      });
    });

    group('Backup Summary', () {
      test('should generate summary from export', () async {
        final bytes = await backupService.exportAll();
        final summary = await backupService.summarize(bytes);
        
        expect(summary, isNotNull);
        expect(summary.platform, anyOf('web', 'native'));
        expect(summary.preferencesCount, greaterThanOrEqualTo(0));
      });

      test('should include all data counts', () async {
        final bytes = await backupService.exportAll();
        final summary = await backupService.summarize(bytes);
        
        expect(summary.users, greaterThanOrEqualTo(0));
        expect(summary.hemogramTests, greaterThanOrEqualTo(0));
        expect(summary.familyMembers, greaterThanOrEqualTo(0));
        expect(summary.reminders, greaterThanOrEqualTo(0));
        expect(summary.notifications, greaterThanOrEqualTo(0));
      });

      test('should handle empty backup', () async {
        final bytes = await backupService.exportAll();
        final summary = await backupService.summarize(bytes);
        
        // Should not throw even if empty
        expect(summary, isNotNull);
      });
    });

    group('Restore All', () {
      test('should restore from valid backup', () async {
        // Create a minimal valid backup
        final backup = {
          'schema': 1,
          'exported_at': DateTime.now().toIso8601String(),
          'platform': 'native',
          'data': {
            'preferences': {},
          },
        };
        
        final bytes = utf8.encode(jsonEncode(backup));
        final result = await backupService.restoreAll(bytes);
        
        expect(result, true);
      });

      test('should handle invalid backup format', () async {
        final invalidBytes = utf8.encode('invalid json');
        
        final result = await backupService.restoreAll(invalidBytes);
        expect(result, false);
      });

      test('should handle missing data section', () async {
        final backup = {
          'schema': 1,
          'exported_at': DateTime.now().toIso8601String(),
        };
        
        final bytes = utf8.encode(jsonEncode(backup));
        final result = await backupService.restoreAll(bytes);
        
        expect(result, false);
      });

      test('should restore preferences', () async {
        final backup = {
          'schema': 1,
          'exported_at': DateTime.now().toIso8601String(),
          'platform': 'native',
          'data': {
            'preferences': {
              'test_bool': true,
              'test_int': 42,
              'test_string': 'test_value',
            },
          },
        };
        
        final bytes = utf8.encode(jsonEncode(backup));
        final result = await backupService.restoreAll(bytes);
        
        expect(result, true);
        
        // Verify preferences were restored
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('test_bool'), true);
        expect(prefs.getInt('test_int'), 42);
        expect(prefs.getString('test_string'), 'test_value');
      });
    });

    group('Error Handling', () {
      test('should handle empty bytes gracefully', () async {
        final result = await backupService.restoreAll([]);
        expect(result, false);
      });

      test('should handle malformed JSON gracefully', () async {
        final malformed = utf8.encode('{invalid json}');
        final result = await backupService.restoreAll(malformed);
        expect(result, false);
      });

      test('should handle restore errors gracefully', () async {
        // Backup with invalid data structure
        final backup = {
          'schema': 1,
          'exported_at': DateTime.now().toIso8601String(),
          'platform': 'native',
          'data': null, // Invalid
        };
        
        final bytes = utf8.encode(jsonEncode(backup));
        final result = await backupService.restoreAll(bytes);
        
        expect(result, false);
      });
    });
  });
}

