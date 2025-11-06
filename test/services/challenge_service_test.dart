import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChallengeService', () {
    late ChallengeService challengeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      challengeService = ChallengeService();
      await challengeService.initialize();
    });

    tearDown(() {
      challengeService.dispose();
    });

    test('should create instance', () {
      expect(challengeService, isNotNull);
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(challengeService.weeklySteps, true);
        expect(challengeService.weeklyWater, true);
        expect(challengeService.weeklySleep, false);
        expect(challengeService.weeklyPoints, 0);
        expect(challengeService.weeklyBadges, 0);
        expect(challengeService.currentStreak, greaterThanOrEqualTo(0));
        expect(challengeService.longestStreak, greaterThanOrEqualTo(0));
      });

      test('should load saved state', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('challenge_state_v2', 
          '{"weeklySteps":false,"weeklyWater":false,"weeklyPoints":100,"currentStreak":5,"longestStreak":10}');
        
        await challengeService.initialize();
        expect(challengeService.weeklySteps, false);
        expect(challengeService.weeklyWater, false);
        expect(challengeService.weeklyPoints, 100);
      });
    });

    group('Toggle Settings', () {
      test('should toggle weekly steps', () async {
        final initial = challengeService.weeklySteps;
        await challengeService.toggleWeeklyStep(!initial);
        expect(challengeService.weeklySteps, !initial);
      });

      test('should toggle weekly water', () async {
        final initial = challengeService.weeklyWater;
        await challengeService.toggleWeeklyWater(!initial);
        expect(challengeService.weeklyWater, !initial);
      });

      test('should toggle weekly sleep', () async {
        final initial = challengeService.weeklySleep;
        await challengeService.toggleWeeklySleep(!initial);
        expect(challengeService.weeklySleep, !initial);
      });
    });

    group('Points Management', () {
      test('should add points', () async {
        final initial = challengeService.weeklyPoints;
        await challengeService.addPoints(10);
        expect(challengeService.weeklyPoints, initial + 10);
      });

      test('should add multiple points', () async {
        await challengeService.addPoints(5);
        await challengeService.addPoints(15);
        expect(challengeService.weeklyPoints, 20);
      });

      test('should reset weekly points', () async {
        await challengeService.addPoints(50);
        await challengeService.resetWeekly();
        expect(challengeService.weeklyPoints, 0);
      });
    });

    group('Streak Management', () {
      test('should track current streak', () {
        expect(challengeService.currentStreak, greaterThanOrEqualTo(0));
      });

      test('should track longest streak', () {
        expect(challengeService.longestStreak, greaterThanOrEqualTo(0));
        expect(challengeService.longestStreak, greaterThanOrEqualTo(challengeService.currentStreak));
      });

      test('should update streak when adding points', () async {
        final initialStreak = challengeService.currentStreak;
        await challengeService.addPoints(10);
        // Streak may increase if it's a new day
        expect(challengeService.currentStreak, greaterThanOrEqualTo(initialStreak));
      });
    });

    group('Badges', () {
      test('should add badge', () async {
        final initial = challengeService.weeklyBadges;
        await challengeService.addBadge();
        expect(challengeService.weeklyBadges, initial + 1);
      });

      test('should reset badges', () async {
        await challengeService.addBadge();
        await challengeService.resetWeekly();
        expect(challengeService.weeklyBadges, 0);
      });
    });

    group('Shared Diet Plans', () {
      test('should have empty shared diets initially', () {
        expect(challengeService.sharedDiets, isEmpty);
      });

      test('should add shared diet plan', () async {
        final plan = SharedDietPlan(
          id: 'test-1',
          name: 'Test Diet',
          month: 202501,
          memberUserIds: [1, 2],
          meta: {'goal': 'weight_loss'},
          points: 100,
        );
        await challengeService.addSharedDiet(plan);
        expect(challengeService.sharedDiets.length, 1);
        expect(challengeService.sharedDiets.first.name, 'Test Diet');
      });

      test('should remove shared diet plan', () async {
        final plan = SharedDietPlan(
          id: 'test-2',
          name: 'Test Diet 2',
          month: 202501,
          memberUserIds: [1],
          meta: {},
          points: 50,
        );
        await challengeService.addSharedDiet(plan);
        expect(challengeService.sharedDiets.length, 1);
        
        await challengeService.removeSharedDiet('test-2');
        expect(challengeService.sharedDiets, isEmpty);
      });
    });
  });
}

