import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/services/backup_service.dart';

void main() {
  group('BackupService summarize & restoreWithStrategy', () {
    test('summarize counts and restore merge/replace', () async {
      // Arrange backup payload
      final backup = {
        'schema': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'platform': 'web',
        'data': {
          'preferences': {'dark_mode': true},
          'web_store': {
            'users': [
              {'id': 1, 'name': 'A'},
              {'id': 2, 'name': 'B'}
            ],
            'hemogram_tests': [],
            'family_members': [],
            'family_invitations': [],
            'per_user': {
              'reminders': {'reminders_u1': '[]'},
              'notifications': {},
              'medications': {},
              'water': {'water_u1_2025-10-01': 5}
            }
          }
        }
      };
      final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(backup));

      // Summarize
      final summary = await BackupService().summarize(bytes);
      expect(summary.platform, 'web');
      expect(summary.preferencesCount, 1);
      expect(summary.users, 2);
      expect(summary.hemogramTests, 0);
      expect(summary.familyMembers, 0);
      expect(summary.familyInvitations, 0);
      expect(summary.reminders, 1);
      expect(summary.notifications, 0);
      expect(summary.medications, 0);
      expect(summary.water, 1);

      // Prepare SharedPreferences mock with existing data
      SharedPreferences.setMockInitialValues({
        'users': [jsonEncode({'id': 1, 'name': 'A'})],
        'hemogram_tests': <String>[],
        'family_members': <String>[],
        'family_invitations': <String>[],
        'reminders_u1': '[]',
        'water_u1_2025-09-30': 3,
      });

      // Merge: should union users by id (1 kept, 2 added), keep existing water key
      var ok = await BackupService().restoreWithStrategy(bytes, strategy: 'merge');
      expect(ok, isTrue);
      final prefs = await SharedPreferences.getInstance();
      final mergedUsers = prefs.getStringList('users') ?? <String>[];
      expect(mergedUsers.length, 2);
      final userIds = mergedUsers.map((s) => (jsonDecode(s) as Map)['id']).toSet();
      expect(userIds.contains(1), isTrue);
      expect(userIds.contains(2), isTrue);
      // Existing key should remain
      expect(prefs.getInt('water_u1_2025-09-30'), 3);
      // Incoming new water key should be written if absent
      expect(prefs.getInt('water_u1_2025-10-01'), 5);

      // Replace: reset store, then apply replace and expect exact backup lists
      SharedPreferences.setMockInitialValues({
        'users': [jsonEncode({'id': 999, 'name': 'X'})],
        'water_u1_2025-09-30': 9,
      });
      ok = await BackupService().restoreWithStrategy(bytes, strategy: 'replace');
      expect(ok, isTrue);
      final prefs2 = await SharedPreferences.getInstance();
      final replacedUsers = prefs2.getStringList('users') ?? <String>[];
      expect(replacedUsers.length, 2);
      final replacedIds = replacedUsers.map((s) => (jsonDecode(s) as Map)['id']).toSet();
      expect(replacedIds.contains(999), isFalse);
      expect(replacedIds.contains(1), isTrue);
      expect(replacedIds.contains(2), isTrue);
      // Replace writes incoming per-user values
      expect(prefs2.getInt('water_u1_2025-10-01'), 5);
    });
  });
}
