import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks lightweight daily wellness metrics and persists them.
/// Keys are namespaced by date (yyyy-mm-dd) so values reset each day.
class WellnessService extends ChangeNotifier {
  static const _kWaterKey = 'wellness_water_ml_';
  static const _kStepsKey = 'wellness_steps_';
  static const _kCaloriesKey = 'wellness_calories_';

  int _waterMl = 0;
  int _steps = 0;
  int _calories = 0;
  String _currentDate = _today();

  int get waterMl => _waterMl;
  int get steps => _steps;
  int get calories => _calories;

  Future<void> initialize() async {
    await _loadForToday();
  }

  Future<void> _loadForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDate = _today();
      _waterMl = prefs.getInt(_kWaterKey + _currentDate) ?? 0;
      _steps = prefs.getInt(_kStepsKey + _currentDate) ?? 0;
      _calories = prefs.getInt(_kCaloriesKey + _currentDate) ?? 0;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = _currentDate;
      await prefs.setInt(_kWaterKey + date, _waterMl);
      await prefs.setInt(_kStepsKey + date, _steps);
      await prefs.setInt(_kCaloriesKey + date, _calories);
    } catch (_) {
      // ignore
    }
  }

  Future<void> addWater(int ml) async {
    _ensureToday();
    _waterMl = (_waterMl + ml).clamp(0, 1000000);
    await _save();
    notifyListeners();
  }

  Future<void> addSteps(int count) async {
    _ensureToday();
    _steps = (_steps + count).clamp(0, 10000000);
    await _save();
    notifyListeners();
  }

  Future<void> addCalories(int kcal) async {
    _ensureToday();
    _calories = (_calories + kcal).clamp(0, 1000000);
    await _save();
    notifyListeners();
  }

  Future<void> setWater(int ml) async {
    _ensureToday();
    _waterMl = ml.clamp(0, 1000000);
    await _save();
    notifyListeners();
  }

  Future<void> setSteps(int count) async {
    _ensureToday();
    _steps = count.clamp(0, 10000000);
    await _save();
    notifyListeners();
  }

  Future<void> setCalories(int kcal) async {
    _ensureToday();
    _calories = kcal.clamp(0, 1000000);
    await _save();
    notifyListeners();
  }

  void _ensureToday() {
    final t = _today();
    if (t != _currentDate) {
      _currentDate = t;
      _waterMl = 0;
      _steps = 0;
      _calories = 0;
    }
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
