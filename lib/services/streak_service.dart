// ignore_for_file: prefer_final_fields
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preferences_service.dart';
import 'activity_service.dart';

/// Streak milestones with rewards
enum StreakMilestone {
  threeDays(3, '🔥', 'Streak Starter'),
  sevenDays(7, '🔥🔥', 'Week Warrior'),
  fourteenDays(14, '🔥🔥🔥', 'Fortnight Fighter'),
  thirtyDays(30, '🏆', 'Monthly Champion'),
  sixtyDays(60, '💎', 'Diamond Dedication'),
  hundredDays(100, '👑', 'Century King'),
  threeSixtyFiveDays(365, '🌟', 'Year Legend');

  final int days;
  final String emoji;
  final String title;

  const StreakMilestone(this.days, this.emoji, this.title);
}

/// Service to manage activity streaks
class StreakService extends ChangeNotifier {
  PreferencesService? _prefs;
  ActivityService? _activityService;

  int? _currentUserId;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDate;
  List<StreakMilestone> _achievedMilestones = [];

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  List<StreakMilestone> get achievedMilestones => _achievedMilestones;

  Future<void> initialize(ActivityService activityService) async {
    _activityService = activityService;
    _prefs = await PreferencesService.getInstance();
    _currentUserId = _prefs?.getCurrentUserId();
    if (_currentUserId != null) {
      await _loadStreak();
      await _checkStreak();
    }
    notifyListeners();
  }

  Future<void> _loadStreak() async {
    if (_currentUserId == null) return;
    try {
      // Load from ChallengeService or calculate from activities
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('streak_$_currentUserId');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _currentStreak = data['current_streak'] as int? ?? 0;
        _longestStreak = data['longest_streak'] as int? ?? 0;
        final last = data['last_active_date'];
        if (last != null) {
          _lastActiveDate = DateTime.tryParse(last as String);
        }
      }
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  Future<void> _saveStreak() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('streak_$_currentUserId', jsonEncode({
        'current_streak': _currentStreak,
        'longest_streak': _longestStreak,
        'last_active_date': _lastActiveDate?.toIso8601String(),
      }));
    } catch (e) {
      debugPrint('Error saving streak: $e');
    }
  }

  /// Check and update streak based on today's activities
  Future<void> _checkStreak() async {
    if (_currentUserId == null || _activityService == null) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final activity = _activityService!.todayActivity;

    if (activity == null) {
      // No activity today, check if streak should break
      if (_lastActiveDate != null) {
        final lastDate = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
        final diff = todayDate.difference(lastDate).inDays;
        if (diff > 1) {
          // Streak broken
          _currentStreak = 0;
          await _saveStreak();
          notifyListeners();
        }
      }
      return;
    }

    final goalsAchieved = activity['goals_achieved'] as int? ?? 0;
    
    // Need at least 2 goals achieved to count as active day
    if (goalsAchieved >= 2) {
      if (_lastActiveDate == null) {
        // First active day
        _currentStreak = 1;
        _longestStreak = 1;
      } else {
        final lastDate = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
        final diff = todayDate.difference(lastDate).inDays;
        
        if (diff == 0) {
          // Same day, no change
          return;
        } else if (diff == 1) {
          // Consecutive day
          _currentStreak++;
          if (_currentStreak > _longestStreak) {
            _longestStreak = _currentStreak;
          }
        } else {
          // Streak broken
          _currentStreak = 1;
        }
      }
      
      _lastActiveDate = todayDate;
      await _checkMilestones();
      await _saveStreak();
      notifyListeners();
    }
  }

  Future<void> _checkMilestones() async {
    final newMilestones = <StreakMilestone>[];
    
    for (final milestone in StreakMilestone.values) {
      if (_currentStreak >= milestone.days) {
        if (!_achievedMilestones.contains(milestone)) {
          newMilestones.add(milestone);
        }
      }
    }
    
    if (newMilestones.isNotEmpty) {
      _achievedMilestones.addAll(newMilestones);
      // Could trigger notification or reward here
      debugPrint('New streak milestones achieved: ${newMilestones.map((m) => m.title).join(", ")}');
    }
  }

  /// Get streak reward info for current streak
  String getStreakReward() {
    for (final milestone in StreakMilestone.values.reversed) {
      if (_currentStreak >= milestone.days) {
        return '${milestone.emoji} ${milestone.title}';
      }
    }
    return '🔥 Keep going!';
  }

  /// Get next milestone
  StreakMilestone? getNextMilestone() {
    for (final milestone in StreakMilestone.values) {
      if (_currentStreak < milestone.days) {
        return milestone;
      }
    }
    return null; // All milestones achieved!
  }

  /// Get progress to next milestone (0.0 to 1.0)
  double getProgressToNextMilestone() {
    final next = getNextMilestone();
    if (next == null) return 1.0;
    
    final previous = StreakMilestone.values.firstWhere(
      (m) => m.days < next.days,
      orElse: () => StreakMilestone.threeDays,
    );
    
    final range = next.days - previous.days;
    final progress = _currentStreak - previous.days;
    return (progress / range).clamp(0.0, 1.0);
  }
}

