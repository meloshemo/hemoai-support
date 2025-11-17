import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChallengeType {
  steps,
  water,
  sleep,
  hemogram,
  diet,
  combined,
}

enum ChallengeDuration {
  daily,
  weekly,
  monthly,
}

class GroupChallenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final ChallengeDuration duration;
  final List<int> participantIds;
  final Map<int, String> participantNames;
  final Map<int, int> participantScores; // userId -> score
  final int targetValue; // Target steps, water ml, etc.
  final DateTime startDate;
  final DateTime endDate;
  final String? createdBy;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  GroupChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.duration,
    required this.participantIds,
    required this.participantNames,
    required this.participantScores,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    this.createdBy,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'duration': duration.name,
        'participantIds': participantIds,
        'participantNames': participantNames.map((k, v) => MapEntry(k.toString(), v)),
        'participantScores': participantScores.map((k, v) => MapEntry(k.toString(), v)),
        'targetValue': targetValue,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'createdBy': createdBy,
        'isActive': isActive,
        'metadata': metadata,
      };

  factory GroupChallenge.fromJson(Map<String, dynamic> json) => GroupChallenge(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ChallengeType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ChallengeType.combined,
        ),
        duration: ChallengeDuration.values.firstWhere(
          (e) => e.name == json['duration'],
          orElse: () => ChallengeDuration.weekly,
        ),
        participantIds: (json['participantIds'] as List).map((e) => e as int).toList(),
        participantNames: (json['participantNames'] as Map).map(
          (k, v) => MapEntry(int.parse(k.toString()), v as String),
        ),
        participantScores: (json['participantScores'] as Map? ?? {}).map(
          (k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()),
        ),
        targetValue: json['targetValue'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        createdBy: json['createdBy'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  List<Map<String, dynamic>> getLeaderboard() {
    final entries = participantScores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) {
      return {
        'userId': entry.key,
        'name': participantNames[entry.key] ?? 'Unknown',
        'score': entry.value,
        'progress': (entry.value / targetValue * 100).clamp(0.0, 100.0),
      };
    }).toList();
  }

  int? getWinnerId() {
    if (participantScores.isEmpty) return null;
    final sorted = participantScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

class GroupChallengeService extends ChangeNotifier {
  static const _prefsKey = 'group_challenges_v1';
  List<GroupChallenge> _challenges = [];

  List<GroupChallenge> get challenges => List.unmodifiable(_challenges);
  List<GroupChallenge> get activeChallenges =>
      _challenges.where((c) => c.isActive && DateTime.now().isBefore(c.endDate)).toList();
  List<GroupChallenge> get completedChallenges =>
      _challenges.where((c) => !c.isActive || DateTime.now().isAfter(c.endDate)).toList();

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = json.decode(raw) as List;
        _challenges = list.map((e) => GroupChallenge.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading group challenges: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _challenges.map((c) => c.toJson()).toList();
      await prefs.setString(_prefsKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving group challenges: $e');
    }
  }

  Future<GroupChallenge> createChallenge({
    required String name,
    required String description,
    required ChallengeType type,
    required ChallengeDuration duration,
    required List<int> participantIds,
    required Map<int, String> participantNames,
    required int targetValue,
    String? createdBy,
  }) async {
    final now = DateTime.now();
    DateTime endDate;
    switch (duration) {
      case ChallengeDuration.daily:
        endDate = now.add(const Duration(days: 1));
        break;
      case ChallengeDuration.weekly:
        endDate = now.add(const Duration(days: 7));
        break;
      case ChallengeDuration.monthly:
        endDate = now.add(const Duration(days: 30));
        break;
    }

    final challenge = GroupChallenge(
      id: '${now.millisecondsSinceEpoch}_${participantIds.join('_')}',
      name: name,
      description: description,
      type: type,
      duration: duration,
      participantIds: participantIds,
      participantNames: participantNames,
      participantScores: {for (var id in participantIds) id: 0},
      targetValue: targetValue,
      startDate: now,
      endDate: endDate,
      createdBy: createdBy,
    );

    _challenges.add(challenge);
    await _save();
    notifyListeners();
    return challenge;
  }

  Future<void> updateParticipantScore(String challengeId, int userId, int score) async {
    final challenge = _challenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => throw Exception('Challenge not found'),
    );

    if (!challenge.participantIds.contains(userId)) {
      throw Exception('User is not a participant');
    }

    final index = _challenges.indexWhere((c) => c.id == challengeId);
    final updatedScores = Map<int, int>.from(challenge.participantScores);
    updatedScores[userId] = score;

    _challenges[index] = GroupChallenge(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      type: challenge.type,
      duration: challenge.duration,
      participantIds: challenge.participantIds,
      participantNames: challenge.participantNames,
      participantScores: updatedScores,
      targetValue: challenge.targetValue,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      createdBy: challenge.createdBy,
      isActive: challenge.isActive,
      metadata: challenge.metadata,
    );

    await _save();
    notifyListeners();
  }

  Future<void> completeChallenge(String challengeId) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return;

    final challenge = _challenges[index];
    _challenges[index] = GroupChallenge(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      type: challenge.type,
      duration: challenge.duration,
      participantIds: challenge.participantIds,
      participantNames: challenge.participantNames,
      participantScores: challenge.participantScores,
      targetValue: challenge.targetValue,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      createdBy: challenge.createdBy,
      isActive: false,
      metadata: challenge.metadata,
    );

    await _save();
    notifyListeners();
  }

  List<GroupChallenge> getChallengesForUser(int userId) {
    return _challenges.where((c) => c.participantIds.contains(userId)).toList();
  }
}

