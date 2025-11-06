import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/services/preferences_service.dart';
import 'package:hemoai/services/web_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile persistence', () {
    test('saves changes and loads after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PreferencesService.getInstance();
      final db = WebDatabaseHelper.instance;
      await db.clearDatabase();

      // Create a user
      final userId = await db.insertUser({
        'name': 'User A',
        'email': 'usera@example.com',
        'phone': '+900000000000',
        'age': 30,
        'gender': 'male',
        'height': 175.0,
        'weight': 75.0,
        'bmi': 24.5,
      });
      await prefs.setCurrentUserId(userId);

      // Update profile fields (simulate edits in PersonalInfoScreen)
      await db.updateUser(userId, {
        'name': 'User A Changed',
        'age': 31,
        'height': 176.0,
        'weight': 76.0,
      });

      // Simulate an app restart by reinitializing the helper
      final db2 = WebDatabaseHelper.instance; // same singleton; SharedPreferences persists
      await db2.init();

      final loaded = await db2.getUserById(userId);
      expect(loaded, isNotNull);
      expect(loaded!['name'], 'User A Changed');
      expect(loaded['age'], 31);
      expect(loaded['height'], 176.0);
      expect(loaded['weight'], 76.0);
    });
  });
}
