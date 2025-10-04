import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-week day completion and cumulative weeks-completed.
/// Resets progress at the start of a new calendar week (Monday-based).
class DietProgressService {
  static const _dayPrefix = 'diet_day_done_'; // 0..6
  static const _weekStartKey = 'diet_week_start_epoch';
  static const _weeksCompletedKey = 'diet_weeks_completed';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  /// Returns Monday 00:00 epoch seconds for the current week.
  int _currentWeekStartEpoch() {
    final now = DateTime.now();
    // Dart weekday: 1=Mon..7=Sun. We want Monday as start.
    final daysFromMonday = (now.weekday - DateTime.monday) % 7; // 0..6
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
    final mondayMidnight = DateTime(monday.year, monday.month, monday.day);
    return (mondayMidnight.millisecondsSinceEpoch / 1000).floor();
    
  }

  Future<void> resetIfNewWeek() async {
    final prefs = await _prefs;
    final current = _currentWeekStartEpoch();
    final stored = prefs.getInt(_weekStartKey) ?? 0;
    if (stored != current) {
      await prefs.setInt(_weekStartKey, current);
      for (int i = 0; i < 7; i++) {
        await prefs.remove('$_dayPrefix$i');
      }
    }
  }

  Future<Map<int, bool>> getWeekProgress() async {
    final prefs = await _prefs;
    final map = <int, bool>{};
    for (int i = 0; i < 7; i++) {
      map[i] = prefs.getBool('$_dayPrefix$i') ?? false;
    }
    return map;
  }

  Future<void> setDayDone(int dayIndex0Sun, bool done) async {
    final prefs = await _prefs;
    await prefs.setBool('$_dayPrefix$dayIndex0Sun', done);
  }

  Future<bool> isWeekCompleted() async {
    final map = await getWeekProgress();
    return map.values.every((v) => v == true);
  }

  Future<int> getWeeksCompleted() async {
    final prefs = await _prefs;
    return prefs.getInt(_weeksCompletedKey) ?? 0;
  }

  Future<int> incrementWeeksCompleted() async {
    final prefs = await _prefs;
    final v = (prefs.getInt(_weeksCompletedKey) ?? 0) + 1;
    await prefs.setInt(_weeksCompletedKey, v);
    return v;
  }
}
