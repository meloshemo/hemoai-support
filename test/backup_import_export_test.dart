import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hemoai/services/database_helper.dart';
import 'package:hemoai/services/backup_service.dart';

void main() {
  setUpAll(() async {
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    SharedPreferences.setMockInitialValues({});
  });

  test('exportAll + summarize includes native DB counts', () async {
    final db = DatabaseHelper.instance;
    await db.clearDatabase();

    final userId = await db.insertUser({
      'name': 'Export User',
      'email': 'export_user@hemoai.com',
      'phone': '+10000000001',
      'password_hash': 'x',
      'age': 28,
      'gender': 'other',
      'height': 171.0,
      'weight': 68.0,
    });

    await db.insertHemogramTest({
      'user_id': userId,
      'test_date': '2025-11-01',
      'hemoglobin': 13.8,
    });

    final bytes = await BackupService().exportAll();
    final summary = await BackupService().summarize(bytes);

    expect(summary.platform, 'native');
    expect(summary.users >= 1, true);
    expect(summary.hemogramTests >= 1, true);
  });

  test('restoreWithStrategy(replace) applies preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final fakeBackup = {
      'schema': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'platform': 'web',
      'data': {
        'preferences': {
          'dark_mode': true,
          'current_user_id': 42,
          'custom_flag': 'on'
        },
        'web_store': {
          'users': [],
          'hemogram_tests': [],
          'family_members': [],
          'family_invitations': [],
          'per_user': {
            'reminders': {},
            'notifications': {},
            'medications': {},
            'water': {},
            'diet': {}
          }
        }
      }
    };

    final bytes = const JsonEncoder.withIndent('  ').convert(fakeBackup).codeUnits;
    final ok = await BackupService().restoreWithStrategy(bytes, strategy: 'replace');
    expect(ok, true);

    final p2 = await SharedPreferences.getInstance();
    expect(p2.getBool('dark_mode'), true);
    expect(p2.getInt('current_user_id'), 42);
    expect(p2.getString('custom_flag'), 'on');
  });
}
