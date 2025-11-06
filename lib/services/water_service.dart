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
    if (userId == null) return;
    final db = DatabaseHelper.instance;
    _todayCount = await db.getTodayWaterIntake(userId);
  }

  Future<void> addGlass(int count) async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) return;
    final db = DatabaseHelper.instance;
    final newVal = _todayCount + count;
    await db.logWaterIntake(userId, newVal);
    _todayCount = newVal;
    await _computeStreak();
    notifyListeners();
  }

  Future<void> _computeStreak() async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) return;
    final db = DatabaseHelper.instance;
    final last7 = await db.getLast7DaysWaterIntake(userId);
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
