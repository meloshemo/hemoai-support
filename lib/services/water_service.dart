import 'package:flutter/foundation.dart';
import 'preferences_service.dart';
import 'database_helper.dart';

class WaterService extends ChangeNotifier {
  int _todayCount = 0;
  int _goal = 8;
  int _streak = 0; // consecutive days meeting goal (based on last 7 days)

  int get todayCount => _todayCount;
  int get goal => _goal;
  int get streak => _streak;

  Future<void> initialize() async {
    final prefs = await PreferencesService.getInstance();
    _goal = prefs.getWaterDailyGoal();
    await _loadToday();
    await _computeStreak();
  }

  Future<void> setGoal(int g) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setWaterDailyGoal(g);
    _goal = g;
    await _computeStreak();
    notifyListeners();
  }

  Future<void> _loadToday() async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) {
      // Test or guest scenario: keep in-memory counter
      _todayCount = 0;
      return;
    }
    final db = DatabaseHelper.instance;
    try {
      _todayCount = await db.getTodayWaterIntake(userId);
    } catch (_) {
      // In tests DB may not be initialized; fall back to memory
      _todayCount = 0;
    }
  }

  Future<void> addGlass(int count) async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    final newVal = _todayCount + count;
    if (userId == null) {
      // Test/guest fallback: adjust local state only
      _todayCount = newVal;
    } else {
      final db = DatabaseHelper.instance;
      try {
        await db.logWaterIntake(userId, newVal);
        _todayCount = newVal;
      } catch (_) {
        _todayCount = newVal; // Fallback if DB unavailable
      }
    }
    await _computeStreak();
    notifyListeners();
  }

  Future<void> _computeStreak() async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) {
      // Simplified streak logic for tests without DB: streak only for current day
      _streak = _todayCount >= _goal ? 1 : 0;
      return;
    }
    final db = DatabaseHelper.instance;
    List<int> last7 = [];
    try {
      last7 = await db.getLast7DaysWaterIntake(userId);
    } catch (_) {
      _streak = _todayCount >= _goal ? 1 : 0;
      return;
    }
    int s = 0;
    // last7 is oldest->newest according to implementation; ensure iterate from newest
    for (int i = last7.length - 1; i >= 0; i--) {
      if ((last7[i]) >= _goal) {
        s++;
      } else {
        break;
      }
    }
    _streak = s;
  }
}
