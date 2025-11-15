import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Web restore (SharedPreferences-based) merge/replace semantics', () {
    setUp(() async {
      // Seed initial web-like store in SharedPreferences
      final existingUsers = [
        jsonEncode({'id': 1, 'name': 'Alice', 'email': 'alice@example.com'}),
      ];
      final existingHemogramTests = [
        jsonEncode({'id': 101, 'user_id': 1, 'test_date': '2025-01-01', 'hemoglobin': 12.5}),
      ];
      SharedPreferences.setMockInitialValues({
        // top-level web store sections
        'users': existingUsers,
        'hemogram_tests': existingHemogramTests,
        'family_members': <String>[],
        'family_invitations': <String>[],
        // per-user maps
        'water_1_2025-01-01': 5, // 5 glasses on that date
        'reminders_1': jsonEncode([{'id': 5001, 'title': 'Test reminder'}]),
      });
    });

    test('merge strategy: unions lists by id and preserves existing per-user keys', () async {
      // Incoming backup (web style)
      final incoming = {
        'schema': 1,
        'platform': 'web',
        'data': {
          'preferences': {
            'current_user_id': 1,
            'dark_mode': true,
          },
          'web_store': {
            'users': [
              {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'}, // overlap
              {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'}, // new
            ],
            'hemogram_tests': [
              {'id': 101, 'user_id': 1, 'test_date': '2025-01-01', 'hemoglobin': 12.5}, // overlap
              {'id': 102, 'user_id': 1, 'test_date': '2025-02-01', 'hemoglobin': 13.1}, // new
            ],
            'family_members': [],
            'family_invitations': [],
            'per_user': {
              'water': {
                'water_1_2025-01-01': 6, // should be ignored in merge (already exists)
                'water_1_2025-01-02': 7, // should be added
              },
              'reminders': {
                'reminders_1': jsonEncode([{'id': 5002, 'title': 'New reminder'}]), // ignored in merge
              },
            },
          },
        },
      };
      final bytes = const JsonEncoder.withIndent('  ').convert(incoming).codeUnits;

      final ok = await BackupService().restoreWithStrategy(bytes, strategy: 'merge');
      expect(ok, true);

      final prefs = await SharedPreferences.getInstance();
      // Users should contain both id=1 and id=2 (union by id)
      final users = prefs.getStringList('users') ?? <String>[];
      final decodedUsers = users.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final ids = decodedUsers.map((m) => m['id']).toSet();
      expect(ids.contains(1), true);
      expect(ids.contains(2), true);

      // Hemogram tests should include 101 and 102
      final hemograms = prefs.getStringList('hemogram_tests') ?? <String>[];
      final hgIds = hemograms.map((s) => (jsonDecode(s) as Map<String, dynamic>)['id']).toSet();
      expect(hgIds.contains(101), true);
      expect(hgIds.contains(102), true);

      // Per-user: merge keeps existing values, adds new ones
      expect(prefs.getInt('water_1_2025-01-01'), 5); // preserved
      expect(prefs.getInt('water_1_2025-01-02'), 7); // added

      // Reminders key preserved (ignored incoming on merge)
      final reminders = prefs.getString('reminders_1');
      expect(reminders, isNotNull);
      expect(reminders!.contains('5001'), true);
    });

    test('replace strategy: overwrites lists and per-user keys', () async {
      final incoming = {
        'schema': 1,
        'platform': 'web',
        'data': {
          'preferences': {
            'current_user_id': 2,
            'dark_mode': false,
          },
          'web_store': {
            'users': [
              {'id': 9, 'name': 'Carol', 'email': 'carol@example.com'},
            ],
            'hemogram_tests': [
              {'id': 999, 'user_id': 9, 'test_date': '2025-03-10', 'hemoglobin': 14.2},
            ],
            'family_members': [],
            'family_invitations': [],
            'per_user': {
              'water': {
                'water_1_2025-01-01': 10, // overwrite existing
              },
              'reminders': {
                'reminders_1': jsonEncode([{'id': 6001, 'title': 'Replaced'}]), // overwrite existing
              },
            },
          },
        },
      };
      final bytes = const JsonEncoder.withIndent('  ').convert(incoming).codeUnits;

      final ok = await BackupService().restoreWithStrategy(bytes, strategy: 'replace');
      expect(ok, true);

      final prefs = await SharedPreferences.getInstance();
      // Users should be replaced with only id=9
      final users = prefs.getStringList('users') ?? <String>[];
      final decodedUsers = users.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      expect(decodedUsers.length, 1);
      expect(decodedUsers.first['id'], 9);

      // Hemogram tests replaced
      final hemograms = prefs.getStringList('hemogram_tests') ?? <String>[];
      final decodedHg = hemograms.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      expect(decodedHg.length, 1);
      expect(decodedHg.first['id'], 999);

      // Per-user keys overwritten
      expect(prefs.getInt('water_1_2025-01-01'), 10);
      final reminders = prefs.getString('reminders_1');
      expect(reminders, isNotNull);
      expect(reminders!.contains('6001'), true);
    });
  });
}
