import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedDietPlan {
  final String id;
  final String name;
  final int month; // yyyymm
  final List<int> memberUserIds; // owner + partner(s)
  final Map<String, dynamic> meta; // notes, goals
  final int points; // monthly score

  SharedDietPlan({required this.id, required this.name, required this.month, required this.memberUserIds, required this.meta, required this.points});

  SharedDietPlan copyWith({String? name, int? points, Map<String, dynamic>? meta, List<int>? memberUserIds}) => SharedDietPlan(
    id: id,
    name: name ?? this.name,
    month: month,
    memberUserIds: memberUserIds ?? this.memberUserIds,
    meta: meta ?? this.meta,
    points: points ?? this.points,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'month': month,
    'memberUserIds': memberUserIds,
    'meta': meta,
    'points': points,
  };

  static SharedDietPlan fromJson(Map<String, dynamic> j) => SharedDietPlan(
    id: j['id'] as String,
    name: j['name'] as String,
    month: j['month'] as int,
    memberUserIds: (j['memberUserIds'] as List).map((e) => e as int).toList(),
    meta: Map<String, dynamic>.from(j['meta'] as Map),
    points: j['points'] as int,
  );
}

class ChallengeService extends ChangeNotifier {
  static const _prefsKey = 'challenge_state_v1';
  static const _sharedDietsKey = 'shared_diets_v1';
  static const _prefsKeyV2 = 'challenge_state_v2';

  bool _weeklySteps = true;
  bool _weeklyWater = true;
  bool _weeklySleep = false;
  int _weeklyPoints = 0;
  int _weeklyBadges = 0;

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDate; // last day user earned points

  List<SharedDietPlan> _sharedDiets = [];

  bool get weeklySteps => _weeklySteps;
  bool get weeklyWater => _weeklyWater;
  bool get weeklySleep => _weeklySleep;
  int get weeklyPoints => _weeklyPoints;
  int get weeklyBadges => _weeklyBadges;
  List<SharedDietPlan> get sharedDiets => List.unmodifiable(_sharedDiets);
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load latest format first
      final rawV2 = prefs.getString(_prefsKeyV2);
      if (rawV2 != null) {
        final m = json.decode(rawV2) as Map<String, dynamic>;
        _weeklySteps = m['weeklySteps'] ?? _weeklySteps;
        _weeklyWater = m['weeklyWater'] ?? _weeklyWater;
        _weeklySleep = m['weeklySleep'] ?? _weeklySleep;
        _weeklyPoints = m['weeklyPoints'] ?? _weeklyPoints;
        _weeklyBadges = m['weeklyBadges'] ?? _weeklyBadges;
        _currentStreak = m['currentStreak'] ?? _currentStreak;
        _longestStreak = m['longestStreak'] ?? _longestStreak;
        final last = m['lastActiveDate'];
        if (last is String && last.isNotEmpty) {
          _lastActiveDate = DateTime.tryParse(last);
        }
      } else {
        // Fallback to v1
        final raw = prefs.getString(_prefsKey);
        if (raw != null) {
          final m = json.decode(raw) as Map<String, dynamic>;
          _weeklySteps = m['weeklySteps'] ?? _weeklySteps;
          _weeklyWater = m['weeklyWater'] ?? _weeklyWater;
          _weeklySleep = m['weeklySleep'] ?? _weeklySleep;
          _weeklyPoints = m['weeklyPoints'] ?? _weeklyPoints;
          _weeklyBadges = m['weeklyBadges'] ?? _weeklyBadges;
        }
      }
      final dietsRaw = prefs.getString(_sharedDietsKey);
      if (dietsRaw != null) {
        final list = (json.decode(dietsRaw) as List)
            .map((e) => SharedDietPlan.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _sharedDiets = list;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ChallengeService] initialize error: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode({
      'weeklySteps': _weeklySteps,
      'weeklyWater': _weeklyWater,
      'weeklySleep': _weeklySleep,
      'weeklyPoints': _weeklyPoints,
      'weeklyBadges': _weeklyBadges,
    }));
    await prefs.setString(_prefsKeyV2, json.encode({
      'weeklySteps': _weeklySteps,
      'weeklyWater': _weeklyWater,
      'weeklySleep': _weeklySleep,
      'weeklyPoints': _weeklyPoints,
      'weeklyBadges': _weeklyBadges,
      'currentStreak': _currentStreak,
      'longestStreak': _longestStreak,
      'lastActiveDate': _lastActiveDate?.toIso8601String(),
    }));
    await prefs.setString(_sharedDietsKey, json.encode(_sharedDiets.map((e) => e.toJson()).toList()));
  }

  Future<void> toggleWeeklyStep(bool v) async { _weeklySteps = v; await _save(); notifyListeners(); }
  Future<void> toggleWeeklyWater(bool v) async { _weeklyWater = v; await _save(); notifyListeners(); }
  Future<void> toggleWeeklySleep(bool v) async { _weeklySleep = v; await _save(); notifyListeners(); }

  // Simple scoring: call when user completes a daily goal
  Future<void> addPoints(int p) async {
    // Update streak if this is a new day of activity
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (_lastActiveDate == null) {
      _currentStreak = 1;
      _longestStreak = _currentStreak;
    } else {
      final last = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
      final diff = todayDate.difference(last).inDays;
      if (diff > 0) {
        if (diff == 1) {
          _currentStreak += 1;
        } else {
          _currentStreak = 1; // reset streak after gap
        }
        if (_currentStreak > _longestStreak) {
          _longestStreak = _currentStreak;
        }
      }
    }
    _lastActiveDate = todayDate;

    _weeklyPoints += p;
    if (_weeklyPoints >= 100) {
      _weeklyBadges += 1;
      _weeklyPoints -= 100;
    }
    await _save();
    notifyListeners();
  }

  Future<void> addBadge() async {
    _weeklyBadges += 1;
    await _save();
    notifyListeners();
  }

  Future<void> resetWeekly() async {
    _weeklyPoints = 0;
    _weeklyBadges = 0;
    await _save();
    notifyListeners();
  }

  // Shared diet plans
  Future<void> createSharedDiet({required String id, required String name, required int month, required List<int> userIds, Map<String, dynamic>? meta}) async {
    _sharedDiets.add(SharedDietPlan(id: id, name: name, month: month, memberUserIds: userIds, meta: meta ?? {}, points: 0));
    await _save();
    notifyListeners();
  }

  Future<void> addSharedDiet(SharedDietPlan plan) async {
    _sharedDiets.add(plan);
    await _save();
    notifyListeners();
  }

  Future<void> removeSharedDiet(String planId) async {
    _sharedDiets.removeWhere((e) => e.id == planId);
    await _save();
    notifyListeners();
  }

  Future<void> addDietPoints(String planId, int points) async {
    final idx = _sharedDiets.indexWhere((e) => e.id == planId);
    if (idx >= 0) {
      _sharedDiets[idx] = _sharedDiets[idx].copyWith(points: _sharedDiets[idx].points + points);
      await _save();
      notifyListeners();
    }
  }
}


