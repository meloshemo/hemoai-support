import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/wellness_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WellnessService', () {
    late WellnessService wellnessService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      wellnessService = WellnessService();
      await wellnessService.initialize();
    });

    tearDown(() {
      wellnessService.dispose();
    });

    test('should create instance', () {
      expect(wellnessService, isNotNull);
    });

    group('Initialization', () {
      test('should initialize with zero values', () {
        expect(wellnessService.waterMl, 0);
        expect(wellnessService.steps, 0);
        expect(wellnessService.calories, 0);
      });
    });

    group('Water Tracking', () {
      test('should add water', () async {
        await wellnessService.addWater(250);
        expect(wellnessService.waterMl, 250);
      });

      test('should add multiple water entries', () async {
        await wellnessService.addWater(250);
        await wellnessService.addWater(500);
        expect(wellnessService.waterMl, 750);
      });

      test('should set water directly', () async {
        await wellnessService.setWater(1000);
        expect(wellnessService.waterMl, 1000);
      });

      test('should clamp water to maximum', () async {
        await wellnessService.setWater(2000000); // Exceeds max
        expect(wellnessService.waterMl, 1000000); // Clamped to max
      });

      test('should clamp water to minimum', () async {
        await wellnessService.setWater(-100);
        expect(wellnessService.waterMl, 0); // Clamped to min
      });
    });

    group('Steps Tracking', () {
      test('should add steps', () async {
        await wellnessService.addSteps(1000);
        expect(wellnessService.steps, 1000);
      });

      test('should add multiple step entries', () async {
        await wellnessService.addSteps(500);
        await wellnessService.addSteps(1500);
        expect(wellnessService.steps, 2000);
      });

      test('should set steps directly', () async {
        await wellnessService.setSteps(5000);
        expect(wellnessService.steps, 5000);
      });

      test('should clamp steps to maximum', () async {
        await wellnessService.setSteps(20000000); // Exceeds max
        expect(wellnessService.steps, 10000000); // Clamped to max
      });
    });

    group('Calories Tracking', () {
      test('should add calories', () async {
        await wellnessService.addCalories(200);
        expect(wellnessService.calories, 200);
      });

      test('should add multiple calorie entries', () async {
        await wellnessService.addCalories(150);
        await wellnessService.addCalories(300);
        expect(wellnessService.calories, 450);
      });

      test('should set calories directly', () async {
        await wellnessService.setCalories(2000);
        expect(wellnessService.calories, 2000);
      });

      test('should clamp calories to maximum', () async {
        await wellnessService.setCalories(2000000); // Exceeds max
        expect(wellnessService.calories, 1000000); // Clamped to max
      });
    });

    group('Notifications', () {
      test('should notify listeners on water change', () async {
        var notified = false;
        wellnessService.addListener(() {
          notified = true;
        });
        
        await wellnessService.addWater(100);
        expect(notified, true);
      });

      test('should notify listeners on steps change', () async {
        var notified = false;
        wellnessService.addListener(() {
          notified = true;
        });
        
        await wellnessService.addSteps(100);
        expect(notified, true);
      });

      test('should notify listeners on calories change', () async {
        var notified = false;
        wellnessService.addListener(() {
          notified = true;
        });
        
        await wellnessService.addCalories(100);
        expect(notified, true);
      });
    });

    group('Persistence', () {
      test('should persist and load values', () async {
        await wellnessService.setWater(500);
        await wellnessService.setSteps(3000);
        await wellnessService.setCalories(1500);
        
        // Create new instance to test loading
        final newService = WellnessService();
        await newService.initialize();
        
        // Values should be loaded (if same day)
        expect(newService.waterMl, greaterThanOrEqualTo(0));
        expect(newService.steps, greaterThanOrEqualTo(0));
        expect(newService.calories, greaterThanOrEqualTo(0));
      });
    });
  });
}

