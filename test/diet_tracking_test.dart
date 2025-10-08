import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/services/web_database_helper.dart';

void main() {
  group('Diet tracking (web) persistence', () {
    setUp(() async {
      // Reset in-memory prefs for each test
      SharedPreferences.setMockInitialValues({});
      final helper = WebDatabaseHelper.instance;
      await helper.init();
    });

    test('upsert and retrieve today tracking', () async {
      final helper = WebDatabaseHelper.instance;
      final userId = 42;
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Initially none
      final initial = await helper.getDietTrackingForDate(userId, today);
      expect(initial, isNull);

      // Upsert values
      final rc = await helper.upsertDietTracking(
        userId: userId,
        date: today,
        breakfast: true,
        lunch: false,
        dinner: true,
        snack: false,
        notes: 'test',
      );
      expect(rc, 1);

      final after = await helper.getDietTrackingForDate(userId, today);
      expect(after, isNotNull);
      expect(after!['breakfast'], 1);
      expect(after['lunch'], 0);
      expect(after['dinner'], 1);
      expect(after['snack'], 0);

      // Update toggles
      await helper.upsertDietTracking(
        userId: userId,
        date: today,
        breakfast: false,
        lunch: true,
        dinner: true,
        snack: true,
      );
      final updated = await helper.getDietTrackingForDate(userId, today);
      expect(updated!['breakfast'], 0);
      expect(updated['lunch'], 1);
      expect(updated['dinner'], 1);
      expect(updated['snack'], 1);
    });
  });
}
