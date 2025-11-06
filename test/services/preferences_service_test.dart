import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService', () {
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferencesService = await PreferencesService.getInstance();
    });

    test('should create singleton instance', () async {
      final instance1 = await PreferencesService.getInstance();
      final instance2 = await PreferencesService.getInstance();
      expect(instance1, equals(instance2));
    });

    group('User Info Management', () {
      test('should save user info', () async {
        await preferencesService.saveUserInfo(
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          age: 25,
          gender: 'male',
          height: 175.0,
          weight: 70.0,
        );
        
        final userInfo = preferencesService.getUserInfo();
        expect(userInfo, isNotNull);
        expect(userInfo!['name'], 'Test User');
        expect(userInfo['age'], 25);
      });

      test('should check if user is logged in', () async {
        expect(preferencesService.isUserLoggedIn(), false);
        
        await preferencesService.saveUserInfo(
          name: 'Test',
          email: 'test@example.com',
          phone: '123',
          age: 25,
          gender: 'male',
          height: 175.0,
          weight: 70.0,
        );
        
        expect(preferencesService.isUserLoggedIn(), true);
      });

      test('should get current user ID', () async {
        final userId = preferencesService.getCurrentUserId();
        expect(userId, anyOf(isNull, isA<int>()));
      });

      test('should set current user ID', () async {
        await preferencesService.setCurrentUserId(123);
        expect(preferencesService.getCurrentUserId(), 123);
      });
    });

    group('Water Tracking', () {
      test('should save and get water count', () async {
        await preferencesService.saveWaterCount(5);
        expect(preferencesService.getWaterCount(), 5);
      });

      test('should reset water count on new day', () async {
        await preferencesService.saveWaterCount(5);
        
        // Simulate new day by setting date manually
        final prefs = await SharedPreferences.getInstance();
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        await prefs.setString('water_date', yesterday.toIso8601String().substring(0, 10));
        
        // Should reset to 0
        final count = preferencesService.getWaterCount();
        expect(count, 0);
      });
    });

    group('Theme Settings', () {
      test('should save and get theme mode', () async {
        await preferencesService.saveThemeMode(true);
        expect(preferencesService.isDarkMode(), true);
        
        await preferencesService.saveThemeMode(false);
        expect(preferencesService.isDarkMode(), false);
      });
    });

    group('First Launch', () {
      test('should detect first launch', () {
        expect(preferencesService.isFirstLaunch(), true);
      });

      test('should set first launch flag', () async {
        await preferencesService.setFirstLaunch(false);
        expect(preferencesService.isFirstLaunch(), false);
      });
    });

    group('Custom Settings', () {
      test('should save and get custom boolean setting', () async {
        await preferencesService.saveCustomSettings('test_bool', true);
        final value = preferencesService.getCustomSetting<bool>('test_bool');
        expect(value, true);
      });

      test('should save and get custom string setting', () async {
        await preferencesService.saveCustomSettings('test_string', 'test_value');
        final value = preferencesService.getCustomSetting<String>('test_string');
        expect(value, 'test_value');
      });

      test('should save and get custom int setting', () async {
        await preferencesService.saveCustomSettings('test_int', 42);
        final value = preferencesService.getCustomSetting<int>('test_int');
        expect(value, 42);
      });

      test('should return null for non-existent setting', () {
        final value = preferencesService.getCustomSetting<String>('non_existent');
        expect(value, isNull);
      });
    });

    group('Water Daily Goal', () {
      test('should get default water goal', () {
        final goal = preferencesService.getWaterDailyGoal();
        expect(goal, greaterThan(0));
      });

      test('should set water daily goal', () async {
        await preferencesService.setWaterDailyGoal(10);
        expect(preferencesService.getWaterDailyGoal(), 10);
      });
    });

    group('Notification Settings', () {
      test('should get default notification settings', () {
        final settings = preferencesService.getNotificationSettings();
        expect(settings, isA<Map<String, bool>>());
        expect(settings.isNotEmpty, true);
      });

      test('should save notification settings', () async {
        final newSettings = {
          'test_reminders': true,
          'critical_alerts': false,
        };
        await preferencesService.saveNotificationSettings(newSettings);
        
        final saved = preferencesService.getNotificationSettings();
        expect(saved['test_reminders'], true);
        expect(saved['critical_alerts'], false);
      });
    });

    group('Medications', () {
      test('should get default medications', () {
        final medications = preferencesService.getMedications();
        expect(medications, isA<List<Map<String, dynamic>>>());
      });

      test('should save medications', () async {
        final medications = [
          {
            'name': 'Aspirin',
            'dosage': '1 tablet',
            'frequency': 'Once daily',
          },
        ];
        await preferencesService.saveMedications(medications);
        
        final saved = preferencesService.getMedications();
        expect(saved.length, 1);
        expect(saved.first['name'], 'Aspirin');
      });
    });

    group('Challenge Settings', () {
      test('should get challenge steps enabled', () {
        expect(preferencesService.getChallengeSteps(), isA<bool>());
      });

      test('should set challenge enabled flags', () async {
        await preferencesService.setChallengeEnabled(steps: false, water: true);
        expect(preferencesService.getChallengeSteps(), false);
        expect(preferencesService.getChallengeWater(), true);
      });

      test('should get motivation tone', () {
        final tone = preferencesService.getMotivationTone();
        expect(tone, anyOf('gentle', 'active'));
      });

      test('should set motivation tone', () async {
        await preferencesService.setMotivationTone('active');
        expect(preferencesService.getMotivationTone(), 'active');
      });
    });

    group('Data Deletion', () {
      test('should clear all local data', () async {
        await preferencesService.saveUserInfo(
          name: 'Test',
          email: 'test@example.com',
          phone: '123',
          age: 25,
          gender: 'male',
          height: 175.0,
          weight: 70.0,
        );
        
        expect(preferencesService.isUserLoggedIn(), true);
        
        await preferencesService.clearAllLocal();
        
        expect(preferencesService.isUserLoggedIn(), false);
      });
    });
  });
}

