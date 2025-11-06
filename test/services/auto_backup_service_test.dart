import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/auto_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoBackupService', () {
    late AutoBackupService autoBackupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      autoBackupService = AutoBackupService();
    });

    test('should create singleton instance', () {
      final instance1 = AutoBackupService();
      final instance2 = AutoBackupService();
      expect(instance1, equals(instance2));
    });

    group('Initialization', () {
      test('should be enabled by default', () async {
        final enabled = await autoBackupService.isEnabled();
        expect(enabled, true);
      });

      test('should have default backup interval', () async {
        final interval = await autoBackupService.getBackupInterval();
        expect(interval, equals(AutoBackupService.defaultBackupIntervalHours));
      });
    });

    group('Enable/Disable', () {
      test('should enable auto backup', () async {
        await autoBackupService.setEnabled(true);
        expect(await autoBackupService.isEnabled(), true);
      });

      test('should disable auto backup', () async {
        await autoBackupService.setEnabled(false);
        expect(await autoBackupService.isEnabled(), false);
      });

      test('should persist enabled state', () async {
        await autoBackupService.setEnabled(true);
        
        final newService = AutoBackupService();
        expect(await newService.isEnabled(), true);
      });
    });

    group('Backup Interval', () {
      test('should set backup interval', () async {
        await autoBackupService.setBackupInterval(12);
        expect(await autoBackupService.getBackupInterval(), 12);
      });

      test('should enforce minimum interval (1 hour)', () async {
        await autoBackupService.setBackupInterval(0);
        expect(await autoBackupService.getBackupInterval(), 1);
      });

      test('should enforce maximum interval (168 hours)', () async {
        await autoBackupService.setBackupInterval(200);
        expect(await autoBackupService.getBackupInterval(), 168);
      });

      test('should persist interval', () async {
        await autoBackupService.setBackupInterval(48);
        
        final newService = AutoBackupService();
        expect(await newService.getBackupInterval(), 48);
      });
    });

    group('Last Backup Time', () {
      test('should return null when never backed up', () async {
        final lastBackup = await autoBackupService.getLastBackupTime();
        expect(lastBackup, isNull);
      });

      test('should calculate time until next backup', () async {
        await autoBackupService.setEnabled(true);
        await autoBackupService.setBackupInterval(24);
        
        // Set a backup time in the past
        final prefs = await SharedPreferences.getInstance();
        final pastTime = DateTime.now().subtract(Duration(hours: 12));
        await prefs.setString('auto_backup_last_run', pastTime.toIso8601String());
        
        final timeUntil = await autoBackupService.getTimeUntilNextBackup();
        expect(timeUntil, isNotNull);
        expect(timeUntil!.inHours, lessThan(24));
      });

      test('should return null when never backed up', () async {
        final timeUntil = await autoBackupService.getTimeUntilNextBackup();
        expect(timeUntil, isNull);
      });
    });

    group('Backup Due Check', () {
      test('should be due when never backed up', () async {
        await autoBackupService.setEnabled(true);
        expect(await autoBackupService.isBackupDue(), true);
      });

      test('should not be due immediately after backup', () async {
        await autoBackupService.setEnabled(true);
        // Set last backup time manually via SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auto_backup_last_run', DateTime.now().toIso8601String());
        
        expect(await autoBackupService.isBackupDue(), false);
      });

      test('should be due after interval expires', () async {
        await autoBackupService.setEnabled(true);
        await autoBackupService.setBackupInterval(1); // 1 hour
        // Set last backup time in the past
        final prefs = await SharedPreferences.getInstance();
        final pastTime = DateTime.now().subtract(Duration(hours: 2));
        await prefs.setString('auto_backup_last_run', pastTime.toIso8601String());
        
        expect(await autoBackupService.isBackupDue(), true);
      });

      test('should not be due when disabled', () async {
        await autoBackupService.setEnabled(false);
        // Set last backup time in the past
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auto_backup_last_run', DateTime.now().subtract(Duration(days: 1)).toIso8601String());
        
        expect(await autoBackupService.isBackupDue(), false);
      });
    });

    group('Edge Cases', () {
      test('should handle invalid timestamp gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auto_backup_last_run', 'invalid-date');
        
        final lastBackup = await autoBackupService.getLastBackupTime();
        expect(lastBackup, isNull);
      });

      test('should handle missing preferences', () async {
        SharedPreferences.setMockInitialValues({});
        final service = AutoBackupService();
        
        expect(await service.isEnabled(), true); // Default
        expect(await service.getBackupInterval(), AutoBackupService.defaultBackupIntervalHours);
      });
    });
  });
}

