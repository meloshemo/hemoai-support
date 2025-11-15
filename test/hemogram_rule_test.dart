import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hemoai/services/database_helper.dart';

void main() {
  setUpAll(() {
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  test('only one active hemogram per user; older/newer logic holds', () async {
    final db = DatabaseHelper.instance;

    await db.clearDatabase();

    final userId = await db.insertUser({
      'name': 'QA User',
      'email': 'qa_user@hemoai.com',
      'phone': '+10000000000',
      'password_hash': 'x',
      'age': 30,
      'gender': 'other',
      'height': 170.0,
      'weight': 70.0,
    });

    // Insert A (2025-10-01) -> becomes active
    await db.insertHemogramTest({
      'user_id': userId,
      'test_date': '2025-10-01',
      'hemoglobin': 13.5,
    });

    var tests = await db.getHemogramTests(userId);
    expect(tests.length, 1);
    expect(tests.first['status'], 'active');

    // Insert B (2025-11-01) -> archives A, B becomes active
    await db.insertHemogramTest({
      'user_id': userId,
      'test_date': '2025-11-01',
      'hemoglobin': 13.7,
    });

    tests = await db.getHemogramTests(userId);
    expect(tests.length, 2);
    expect(tests[0]['test_date'], '2025-11-01');
    expect(tests[0]['status'], 'active');
    expect(tests[1]['test_date'], '2025-10-01');
    expect(tests[1]['status'], 'archived');

    // Insert C (2025-09-01) -> is older than active; should be archived on insert
    await db.insertHemogramTest({
      'user_id': userId,
      'test_date': '2025-09-01',
      'hemoglobin': 13.2,
    });

    tests = await db.getHemogramTests(userId);
    expect(tests.length, 3);
    // Still only one active (the latest, 2025-11-01)
    final activeCount = tests.where((t) => t['status'] == 'active').length;
    expect(activeCount, 1);
    expect(tests[0]['test_date'], '2025-11-01');
    expect(tests[0]['status'], 'active');
    expect(tests[1]['test_date'], '2025-10-01');
    expect(tests[1]['status'], 'archived');
    expect(tests[2]['test_date'], '2025-09-01');
    expect(tests[2]['status'], 'archived');
  });
}
