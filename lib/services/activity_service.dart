import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'preferences_service.dart';
import 'points_calculator.dart';
import 'social_challenge_service.dart';

/// Service to manage all daily activities (steps, sleep, water, points)
class ActivityService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  PreferencesService? _prefs;
  SocialChallengeService? _socialService;

  int? _currentUserId;
  Map<String, dynamic>? _todayActivity;
  Map<String, dynamic>? _userGoals;

  void setSocialService(SocialChallengeService service) {
    _socialService = service;
  }

  int? get currentUserId => _currentUserId;
  Map<String, dynamic>? get todayActivity => _todayActivity;
  Map<String, dynamic>? get userGoals => _userGoals;

  Future<void> initialize() async {
    _prefs = await PreferencesService.getInstance();
    _currentUserId = _prefs?.getCurrentUserId();
    if (_currentUserId != null) {
      await _loadUserGoals();
      await _loadTodayActivity();
    }
    notifyListeners();
  }

  Future<void> _loadUserGoals() async {
    if (_currentUserId == null) return;
    try {
      _userGoals = await _db.getUserGoals(_currentUserId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user goals: $e');
    }
  }

  Future<void> _loadTodayActivity() async {
    if (_currentUserId == null) return;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      _todayActivity = await _db.getDailyActivity(_currentUserId!, today);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading today activity: $e');
    }
  }

  Future<void> setStepsGoal(int goal) async {
    if (_currentUserId == null) return;
    await _db.updateUserGoals(_currentUserId!, stepsGoal: goal);
    await _loadUserGoals();
  }

  Future<void> setWaterGoal(int goal) async {
    if (_currentUserId == null) return;
    await _db.updateUserGoals(_currentUserId!, waterGoal: goal);
    await _loadUserGoals();
  }

  Future<void> setSleepGoal(int goal) async {
    if (_currentUserId == null) return;
    await _db.updateUserGoals(_currentUserId!, sleepGoal: goal);
    await _loadUserGoals();
  }

  Future<int> logSteps(int steps, {String? date}) async {
    if (_currentUserId == null) return 0;
    final result = await _db.logSteps(_currentUserId!, steps, date: date);
    await _recalculatePoints(date: date);
    await _loadTodayActivity();
    await _syncToSocialService(date: date);
    return result;
  }

  Future<int> logSleep(int sleepMinutes, {String? date}) async {
    if (_currentUserId == null) return 0;
    final result = await _db.logSleep(_currentUserId!, sleepMinutes, date: date);
    await _recalculatePoints(date: date);
    await _loadTodayActivity();
    await _syncToSocialService(date: date);
    return result;
  }

  Future<void> _syncToSocialService({String? date}) async {
    if (_currentUserId == null || _socialService == null || _userGoals == null) return;
    
    final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    final activity = await _db.getDailyActivity(_currentUserId!, targetDate);
    
    if (activity != null) {
      final steps = (activity['steps'] as num?)?.toInt() ?? 0;
      final waterGlasses = (activity['water_glasses'] as num?)?.toInt() ?? 0;
      final sleepMinutes = (activity['sleep_minutes'] as num?)?.toInt() ?? 0;
      final points = (activity['points'] as num?)?.toInt() ?? 0;
      
      final userName = _prefs?.getUserInfo()?['name'] as String? ?? 'User';
      
      await _socialService!.updateActivityData(
        userId: _currentUserId!,
        userName: userName,
        steps: steps,
        water: waterGlasses,
        sleep: sleepMinutes,
        points: points,
        date: DateTime.parse(targetDate),
      );
    }
  }

  Future<void> _recalculatePoints({String? date}) async {
    if (_currentUserId == null || _userGoals == null) return;
    
    final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    final activity = await _db.getDailyActivity(_currentUserId!, targetDate);
    
    final steps = (activity?['steps'] as num?)?.toInt() ?? 0;
    final waterGlasses = (activity?['water_glasses'] as num?)?.toInt() ?? 0;
    final sleepMinutes = (activity?['sleep_minutes'] as num?)?.toInt() ?? 0;
    
    final stepsGoal = _userGoals!['steps_goal'] as int? ?? 10000;
    final waterGoal = _userGoals!['water_goal'] as int? ?? 8;
    final sleepGoal = _userGoals!['sleep_goal'] as int? ?? 480;

    final pointsData = PointsCalculator.calculateDailyPoints(
      steps: steps,
      waterGlasses: waterGlasses,
      sleepMinutes: sleepMinutes,
      stepsGoal: stepsGoal,
      waterGoal: waterGoal,
      sleepGoal: sleepGoal,
    );

    // Update points in database
    await _updateActivityPoints(
      targetDate,
      pointsData['total_points'] as int,
      pointsData['goals_achieved'] as int,
    );
  }

  Future<void> _updateActivityPoints(String date, int points, int goalsAchieved) async {
    if (_currentUserId == null) return;
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    
    if (kIsWeb) {
      // Web implementation
      return;
    } else {
      final existing = await db.query(
        'daily_activities',
        where: 'user_id = ? AND date = ?',
        whereArgs: [_currentUserId, date],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await db.update(
          'daily_activities',
          {
            'points': points,
            'goals_achieved': goalsAchieved,
            'updated_at': now,
          },
          where: 'user_id = ? AND date = ?',
          whereArgs: [_currentUserId, date],
        );
      } else {
        await db.insert('daily_activities', {
          'user_id': _currentUserId,
          'date': date,
          'steps': 0,
          'sleep_minutes': 0,
          'water_glasses': 0,
          'points': points,
          'goals_achieved': goalsAchieved,
          'created_at': now,
          'updated_at': now,
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivities({DateTime? startDate}) async {
    if (_currentUserId == null) return [];
    return await _db.getWeeklyActivities(_currentUserId!, startDate: startDate);
  }

  Future<List<Map<String, dynamic>>> getMonthlyActivities({DateTime? startDate}) async {
    if (_currentUserId == null) return [];
    return await _db.getMonthlyActivities(_currentUserId!, startDate: startDate);
  }

  Future<Map<String, dynamic>> getWeeklyStats({DateTime? startDate}) async {
    final activities = await getWeeklyActivities(startDate: startDate);
    final stepsGoal = _userGoals?['steps_goal'] as int? ?? 10000;
    final waterGoal = _userGoals?['water_goal'] as int? ?? 8;
    final sleepGoal = _userGoals?['sleep_goal'] as int? ?? 480;

    int totalSteps = 0;
    int totalWater = 0;
    int totalSleep = 0;
    int totalPoints = 0;

    for (final activity in activities) {
      totalSteps += (activity['steps'] as num?)?.toInt() ?? 0;
      totalWater += (activity['water_glasses'] as num?)?.toInt() ?? 0;
      totalSleep += (activity['sleep_minutes'] as num?)?.toInt() ?? 0;
      totalPoints += (activity['points'] as num?)?.toInt() ?? 0;
    }

    return {
      'steps': totalSteps,
      'steps_goal': stepsGoal * 7,
      'water': totalWater,
      'water_goal': waterGoal * 7,
      'sleep': totalSleep,
      'sleep_goal': sleepGoal * 7,
      'points': totalPoints,
    };
  }

  Future<Map<String, dynamic>> getMonthlyStats({DateTime? startDate}) async {
    final activities = await getMonthlyActivities(startDate: startDate);
    final stepsGoal = _userGoals?['steps_goal'] as int? ?? 10000;
    final waterGoal = _userGoals?['water_goal'] as int? ?? 8;
    final sleepGoal = _userGoals?['sleep_goal'] as int? ?? 480;
    final days = activities.isNotEmpty ? activities.length : 30;

    int totalSteps = 0;
    int totalWater = 0;
    int totalSleep = 0;
    int totalPoints = 0;

    for (final activity in activities) {
      totalSteps += (activity['steps'] as num?)?.toInt() ?? 0;
      totalWater += (activity['water_glasses'] as num?)?.toInt() ?? 0;
      totalSleep += (activity['sleep_minutes'] as num?)?.toInt() ?? 0;
      totalPoints += (activity['points'] as num?)?.toInt() ?? 0;
    }

    return {
      'steps': totalSteps,
      'steps_goal': stepsGoal * days,
      'water': totalWater,
      'water_goal': waterGoal * days,
      'sleep': totalSleep,
      'sleep_goal': sleepGoal * days,
      'points': totalPoints,
      'avg_steps_per_day': days > 0 ? (totalSteps / days).round() : 0,
    };
  }
}

