import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/water_service.dart';
import 'package:hemoai/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WaterService', () {
    late WaterService waterService;
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferencesService = await PreferencesService.getInstance();
      waterService = WaterService();
      await waterService.initialize();
    });

    tearDown(() {
      waterService.dispose();
    });

    test('should create instance', () {
      expect(waterService, isNotNull);
    });

    group('Initialization', () {
      test('should initialize with default goal', () {
        expect(waterService.goal, 8); // Default goal
        expect(waterService.todayCount, 0);
        expect(waterService.streak, greaterThanOrEqualTo(0));
      });

      test('should load saved goal', () async {
        await preferencesService.setWaterDailyGoal(10);
        await waterService.initialize();
        expect(waterService.goal, 10);
      });
    });

    group('Goal Management', () {
      test('should set goal', () async {
        await waterService.setGoal(10);
        expect(waterService.goal, 10);
      });

      test('should update goal and notify listeners', () async {
        var notified = false;
        waterService.addListener(() {
          notified = true;
        });
        
        await waterService.setGoal(12);
        expect(waterService.goal, 12);
        expect(notified, true);
      });
    });

    group('Water Intake', () {
      test('should add glass of water', () async {
        final initial = waterService.todayCount;
        await waterService.addGlass(1);
        expect(waterService.todayCount, initial + 1);
      });

      test('should add multiple glasses', () async {
        await waterService.addGlass(2);
        await waterService.addGlass(3);
        expect(waterService.todayCount, 5);
      });

      test('should notify listeners when adding water', () async {
        var notified = false;
        waterService.addListener(() {
          notified = true;
        });
        
        await waterService.addGlass(1);
        expect(notified, true);
      });
    });

    group('Streak Calculation', () {
      test('should calculate streak based on goal', () {
        expect(waterService.streak, greaterThanOrEqualTo(0));
        expect(waterService.streak, lessThanOrEqualTo(7)); // Max 7 days
      });

      test('should update streak when goal is met', () async {
        // This would require database setup for full test
        // Placeholder for integration test
        expect(waterService.streak, isA<int>());
      });
    });

    group('Edge Cases', () {
      test('should handle zero glasses', () async {
        await waterService.addGlass(0);
        expect(waterService.todayCount, 0);
      });

      test('should handle large numbers', () async {
        await waterService.addGlass(100);
        expect(waterService.todayCount, 100);
      });
    });
  });
}

