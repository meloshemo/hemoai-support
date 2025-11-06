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
  static const _prefsKey = 'challenge_state_v2'; // Updated for streak support
  static const _sharedDietsKey = 'shared_diets_v1';

  bool _weeklySteps = true;
  bool _weeklyWater = true;
  bool _weeklySleep = false;
  int _weeklyPoints = 0;
  int _weeklyBadges = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActivityDate;

  List<SharedDietPlan> _sharedDiets = [];

  bool get weeklySteps => _weeklySteps;
  bool get weeklyWater => _weeklyWater;
  bool get weeklySleep => _weeklySleep;
  int get weeklyPoints => _weeklyPoints;
  int get weeklyBadges => _weeklyBadges;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  List<SharedDietPlan> get sharedDiets => List.unmodifiable(_sharedDiets);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final m = json.decode(raw) as Map<String, dynamic>;
        _weeklySteps = m['weeklySteps'] ?? _weeklySteps;
        _weeklyWater = m['weeklyWater'] ?? _weeklyWater;
        _weeklySleep = m['weeklySleep'] ?? _weeklySleep;
        _weeklyPoints = m['weeklyPoints'] ?? _weeklyPoints;
        _weeklyBadges = m['weeklyBadges'] ?? _weeklyBadges;
        _currentStreak = m['currentStreak'] ?? 0;
        _longestStreak = m['longestStreak'] ?? 0;
        if (m['lastActivityDate'] != null) {
          _lastActivityDate = DateTime.parse(m['lastActivityDate'] as String);
        }
        _updateStreak();
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

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastActivityDate == null) {
      _lastActivityDate = today;
      _currentStreak = 1;
      return;
    }

    final lastDate = DateTime(_lastActivityDate!.year, _lastActivityDate!.month, _lastActivityDate!.day);
    final daysDiff = today.difference(lastDate).inDays;

    if (daysDiff == 0) {
      // Same day, no change
      return;
    } else if (daysDiff == 1) {
      // Consecutive day
      _currentStreak++;
      _lastActivityDate = today;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    } else {
      // Streak broken
      _currentStreak = 1;
      _lastActivityDate = today;
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
      'currentStreak': _currentStreak,
      'longestStreak': _longestStreak,
      'lastActivityDate': _lastActivityDate?.toIso8601String(),
    }));
    await prefs.setString(_sharedDietsKey, json.encode(_sharedDiets.map((e) => e.toJson()).toList()));
  }

  Future<void> toggleWeeklyStep(bool v) async { _weeklySteps = v; await _save(); notifyListeners(); }
  Future<void> toggleWeeklyWater(bool v) async { _weeklyWater = v; await _save(); notifyListeners(); }
  Future<void> toggleWeeklySleep(bool v) async { _weeklySleep = v; await _save(); notifyListeners(); }

  // Simple scoring: call when user completes a daily goal
  Future<void> addPoints(int p) async {
    _updateStreak();
    _weeklyPoints += p;
    if (_weeklyPoints >= 100) {
      _weeklyBadges += 1;
      _weeklyPoints -= 100;
    }
    await _save();
    notifyListeners();
  }

  // Shared diet plans
  Future<void> createSharedDiet({required String id, required String name, required int month, required List<int> userIds, Map<String, dynamic>? meta}) async {
    _sharedDiets.add(SharedDietPlan(id: id, name: name, month: month, memberUserIds: userIds, meta: meta ?? {}, points: 0));
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


