import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/database_helper.dart';
import 'package:hemoai/services/preferences_service.dart';
import 'package:hemoai/services/notification_service.dart' as inapp;
import 'package:hemoai/services/backup_service.dart';
import 'package:hemoai/services/auto_backup_service.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OS4 scenarios: hemogram + airplane mode, backup import/export', () {
    late int userId;

    setUp(() async {
      // Set up mock SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
      // Create a fresh test user and set preferences
      final db = DatabaseHelper.instance;
      final nowIso = DateTime.now().toIso8601String();
      final id = await db.insertUser({
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+900000000000',
        'password_hash': 'test-hash',
        'age': 30,
        'gender': 'male',
        'height': 175.0,
        'weight': 72.0,
        'bmi': 23.5,
        'email_verified': 0,
        'phone_verified': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
      userId = id;
      final prefs = await PreferencesService.getInstance();
      await prefs.setUserId(userId);
      await AutoBackupService().setEnabled(true);
    });

    test('Hemogram insertion appears active and latest', () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final testRow = {
        'user_id': userId,
        'test_date': now.toIso8601String(),
        'hemoglobin': 13.6,
        'status': 'active',
      };
      final insertedId = await db.insertHemogramTest(testRow);
      expect(insertedId, greaterThan(0));

      final rows = await db.getHemogramTests(userId);
      expect(rows.isNotEmpty, true);
      final latest = rows.first;
      expect(latest['status'], 'active');
      expect((latest['hemoglobin'] as num).toDouble(), closeTo(13.6, 0.0001));
    });

  test('Airplane mode like edit: local reminder update persists', () async {
      // Create a local in-app reminder and update time/description
      final service = inapp.NotificationService();
      service.initialize();
      final when = DateTime.now().add(const Duration(hours: 1));
      final reminder = inapp.NotificationItem(
        title: LocalizationService().getString('medication_reminder_title'),
        description: LocalizationService().getStringWithParams('medication_reminder_body', {
          'medication': 'Ferrous Sulfate',
          'dosage_text': '',
        }),
        scheduledTime: when,
        type: inapp.NotificationType.medication,
        repeatType: inapp.RepeatType.daily,
      );
      await service.addNotification(reminder);
      expect(service.totalNotifications, greaterThan(0));
      final id = service.notifications.last.id!;

      // Simulate an edit while "offline": update time/description locally
      final newWhen = when.add(const Duration(minutes: 30));
      await service.updateScheduledTime(id, newWhen);
  final updated = service.notifications.firstWhere((n) => n.id == id);
  expect(updated.scheduledTime.isAtSameMomentAs(newWhen), true);

      // Optional: export snapshot to confirm backup path is available
  final bytes = await BackupService().exportAll();
  // Non-fatal in headless test env if empty; just ensure no exception thrown
  expect(bytes, isA<List<int>>());
    });

  test('Export backup and summarize contents', () async {
      final db = DatabaseHelper.instance;
      final prefs = await PreferencesService.getInstance();
      final loc = LocalizationService();

      // Seed some data
      await db.insertHemogramTest({
        'user_id': userId,
        'test_date': DateTime.now().toIso8601String(),
        'hemoglobin': 12.9,
        'status': 'active',
      });

      final inApp = inapp.NotificationService();
      final r = inApp.createTestReminder(
        testName: 'CRP',
        time: DateTime.now().add(const Duration(hours: 2)),
      );
      await inApp.addNotification(r);

      await prefs.saveCustomSettings('daily_motivation_hour', 8);
      await prefs.saveCustomSettings('daily_motivation_minute', 0);

      // Export
      final bytes = await BackupService().exportAll();
      expect(bytes.isNotEmpty, true);

      // Clear local DB minimally by creating a new user context
      final nowIso2 = DateTime.now().toIso8601String();
      final newUserId = await db.insertUser({
        'name': 'Restore User',
        'email': 'restore@example.com',
        'phone': '+900000000001',
        'password_hash': 'restore-hash',
        'age': 28,
        'gender': 'female',
        'height': 165.0,
        'weight': 60.0,
        'bmi': 22.0,
        'email_verified': 0,
        'phone_verified': 0,
        'created_at': nowIso2,
        'updated_at': nowIso2,
      });
      await prefs.setUserId(newUserId);

  // Summarize and validate structure without performing destructive restore in native mode
  final summary = await BackupService().summarize(bytes);
  expect(summary.preferencesCount, greaterThanOrEqualTo(1));
  expect(summary.hemogramTests, greaterThanOrEqualTo(1));

      // Localization sanity (no hardcoded literals)
      final savedMsg = loc.getString('notification_settings_saved');
      expect(savedMsg.isNotEmpty, true);
    });
  });
}
