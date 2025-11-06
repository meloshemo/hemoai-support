import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Friend connection with mutual approval
class FriendConnection {
  final String id;
  final int friendUserId;
  final String friendName;
  final String? friendAvatar; // Avatar emoji or icon
  final bool isApprovedByMe; // User approved the connection
  final bool isApprovedByFriend; // Friend approved the connection
  final DateTime createdAt;
  final DateTime? approvedAt;

  FriendConnection({
    required this.id,
    required this.friendUserId,
    required this.friendName,
    this.friendAvatar,
    required this.isApprovedByMe,
    required this.isApprovedByFriend,
    required this.createdAt,
    this.approvedAt,
  });

  bool get isActive => isApprovedByMe && isApprovedByFriend;

  Map<String, dynamic> toJson() => {
    'id': id,
    'friendUserId': friendUserId,
    'friendName': friendName,
    'friendAvatar': friendAvatar,
    'isApprovedByMe': isApprovedByMe,
    'isApprovedByFriend': isApprovedByFriend,
    'createdAt': createdAt.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
  };

  factory FriendConnection.fromJson(Map<String, dynamic> json) => FriendConnection(
    id: json['id'] as String,
    friendUserId: json['friendUserId'] as int,
    friendName: json['friendName'] as String,
    friendAvatar: json['friendAvatar'] as String?,
    isApprovedByMe: json['isApprovedByMe'] as bool,
    isApprovedByFriend: json['isApprovedByFriend'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
  );

  FriendConnection copyWith({
    bool? isApprovedByMe,
    bool? isApprovedByFriend,
    DateTime? approvedAt,
  }) => FriendConnection(
    id: id,
    friendUserId: friendUserId,
    friendName: friendName,
    friendAvatar: friendAvatar,
    isApprovedByMe: isApprovedByMe ?? this.isApprovedByMe,
    isApprovedByFriend: isApprovedByFriend ?? this.isApprovedByFriend,
    createdAt: createdAt,
    approvedAt: approvedAt ?? this.approvedAt,
  );
}

/// Shared activity data (steps, water, sleep)
class SharedActivityData {
  final int userId;
  final String userName;
  final String? userAvatar;
  final int steps;
  final int water; // ml
  final int sleep; // minutes
  final DateTime date;
  final int points;

  SharedActivityData({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.steps,
    required this.water,
    required this.sleep,
    required this.date,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'steps': steps,
    'water': water,
    'sleep': sleep,
    'date': date.toIso8601String(),
    'points': points,
  };

  factory SharedActivityData.fromJson(Map<String, dynamic> json) => SharedActivityData(
    userId: json['userId'] as int,
    userName: json['userName'] as String,
    userAvatar: json['userAvatar'] as String?,
    steps: json['steps'] as int,
    water: json['water'] as int,
    sleep: json['sleep'] as int,
    date: DateTime.parse(json['date'] as String),
    points: json['points'] as int,
  );
}

/// Competition between friends
class FriendCompetition {
  final String id;
  final int myUserId;
  final int friendUserId;
  final String friendName;
  final String? friendAvatar;
  final int mySteps;
  final int friendSteps;
  final int myWater;
  final int friendWater;
  final int mySleep;
  final int friendSleep;
  final int myPoints;
  final int friendPoints;
  final DateTime date;

  FriendCompetition({
    required this.id,
    required this.myUserId,
    required this.friendUserId,
    required this.friendName,
    this.friendAvatar,
    required this.mySteps,
    required this.friendSteps,
    required this.myWater,
    required this.friendWater,
    required this.mySleep,
    required this.friendSleep,
    required this.myPoints,
    required this.friendPoints,
    required this.date,
  });

  bool get iAmWinning {
    final myTotal = mySteps + myWater + mySleep;
    final friendTotal = friendSteps + friendWater + friendSleep;
    return myTotal > friendTotal;
  }

  int get pointsDifference => (mySteps + myWater + mySleep) - (friendSteps + friendWater + friendSleep);
}

class SocialChallengeService extends ChangeNotifier {
  static const String _friendsKey = 'social_friends_v1';
  static const String _activityDataKey = 'social_activity_data_v1';
  static const String _competitionsKey = 'social_competitions_v1';

  List<FriendConnection> _friends = [];
  Map<String, SharedActivityData> _activityData = {}; // key: userId_date
  List<FriendCompetition> _competitions = [];

  List<FriendConnection> get friends => List.unmodifiable(_friends);
  List<FriendConnection> get activeFriends => _friends.where((f) => f.isActive).toList();
  List<FriendConnection> get pendingFriends => _friends.where((f) => !f.isActive).toList();
  List<FriendCompetition> get competitions => List.unmodifiable(_competitions);
  Map<String, SharedActivityData> get activityData => Map.unmodifiable(_activityData);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load friends
      final friendsRaw = prefs.getString(_friendsKey);
      if (friendsRaw != null) {
        final list = (json.decode(friendsRaw) as List)
            .map((e) => FriendConnection.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _friends = list;
      }

      // Load activity data
      final activityRaw = prefs.getString(_activityDataKey);
      if (activityRaw != null) {
        final map = json.decode(activityRaw) as Map<String, dynamic>;
        _activityData = map.map((key, value) => MapEntry(
          key,
          SharedActivityData.fromJson(Map<String, dynamic>.from(value)),
        ));
      }

      // Load competitions
      final competitionsRaw = prefs.getString(_competitionsKey);
      if (competitionsRaw != null) {
        final list = (json.decode(competitionsRaw) as List)
            .map((e) => friendCompetitionFromJson(Map<String, dynamic>.from(e)))
            .toList();
        _competitions = list;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[SocialChallengeService] Initialize error: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_friendsKey, json.encode(_friends.map((f) => f.toJson()).toList()));
    await prefs.setString(_activityDataKey, json.encode(_activityData.map((key, value) => MapEntry(key, value.toJson()))));
    await prefs.setString(_competitionsKey, json.encode(_competitions.map((c) => c.toJson()).toList()));
  }

  /// Send friend request (creates pending connection)
  Future<String> sendFriendRequest({
    required int friendUserId,
    required String friendName,
    String? friendAvatar,
  }) async {
    final id = 'friend_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final connection = FriendConnection(
      id: id,
      friendUserId: friendUserId,
      friendName: friendName,
      friendAvatar: friendAvatar,
      isApprovedByMe: true,
      isApprovedByFriend: false,
      createdAt: DateTime.now(),
    );
    _friends.add(connection);
    await _save();
    notifyListeners();
    return id;
  }

  /// Approve friend request
  Future<void> approveFriendRequest(String connectionId) async {
    final idx = _friends.indexWhere((f) => f.id == connectionId);
    if (idx >= 0) {
      _friends[idx] = _friends[idx].copyWith(
        isApprovedByFriend: true,
        approvedAt: DateTime.now(),
      );
      await _save();
      notifyListeners();
    }
  }

  /// Remove friend connection
  Future<void> removeFriend(String connectionId) async {
    _friends.removeWhere((f) => f.id == connectionId);
    await _save();
    notifyListeners();
  }

  /// Update activity data (steps, water, sleep)
  Future<void> updateActivityData({
    required int userId,
    required String userName,
    String? userAvatar,
    required int steps,
    required int water,
    required int sleep,
    required int points,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final key = '${userId}_${targetDate.year}_${targetDate.month}_${targetDate.day}';
    
    final activity = SharedActivityData(
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      steps: steps,
      water: water,
      sleep: sleep,
      date: targetDate,
      points: points,
    );
    
    _activityData[key] = activity;
    await _save();
    
    // Update competitions
    await _updateCompetitions(userId, targetDate);
    notifyListeners();
  }

  /// Get friend's activity data
  List<SharedActivityData> getFriendActivity(int friendUserId, {int days = 7}) {
    final now = DateTime.now();
    final activities = <SharedActivityData>[];
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${friendUserId}_${date.year}_${date.month}_${date.day}';
      final activity = _activityData[key];
      if (activity != null) {
        activities.add(activity);
      }
    }
    
    return activities.reversed.toList();
  }

  /// Get competition data for today
  FriendCompetition? getTodayCompetition(int myUserId, int friendUserId) {
    final today = DateTime.now();
    return _competitions.firstWhere(
      (c) => c.myUserId == myUserId && 
             c.friendUserId == friendUserId && 
             c.date.year == today.year &&
             c.date.month == today.month &&
             c.date.day == today.day,
      orElse: () => throw StateError('No competition found'),
    );
  }

  /// Update competitions when activity changes
  Future<void> _updateCompetitions(int userId, DateTime date) async {
    // Find active friends
    final activeFriends = _friends.where((f) => f.isActive && f.friendUserId != userId).toList();
    
    for (final friend in activeFriends) {
      final myKey = '${userId}_${date.year}_${date.month}_${date.day}';
      final friendKey = '${friend.friendUserId}_${date.year}_${date.month}_${date.day}';
      
      final myActivity = _activityData[myKey];
      final friendActivity = _activityData[friendKey];
      
      if (myActivity != null && friendActivity != null) {
        final competitionId = 'comp_${userId}_${friend.friendUserId}_${date.year}_${date.month}_${date.day}';
        
        // Remove old competition if exists
        _competitions.removeWhere((c) => c.id == competitionId);
        
        // Create new competition
        final competition = FriendCompetition(
          id: competitionId,
          myUserId: userId,
          friendUserId: friend.friendUserId,
          friendName: friend.friendName,
          friendAvatar: friend.friendAvatar,
          mySteps: myActivity.steps,
          friendSteps: friendActivity.steps,
          myWater: myActivity.water,
          friendWater: friendActivity.water,
          mySleep: myActivity.sleep,
          friendSleep: friendActivity.sleep,
          myPoints: myActivity.points,
          friendPoints: friendActivity.points,
          date: date,
        );
        
        _competitions.add(competition);
      }
    }
    
    await _save();
  }

  /// Generate avatar variant index (for LabubuAvatar)
  /// Returns a consistent index based on seed for the same user
  int generateAvatarVariantIndex({String? seed}) {
    if (seed != null) {
      return seed.hashCode.abs() % 1000; // Large variety
    }
    return Random().nextInt(1000);
  }

  /// Generate avatar (legacy method - now returns variant index as string)
  /// Kept for backward compatibility
  String generateAvatar({String? seed}) {
    // Return variant index as string for compatibility
    return generateAvatarVariantIndex(seed: seed).toString();
  }
}

// FriendCompetition JSON serialization methods
extension FriendCompetitionJson on FriendCompetition {
  Map<String, dynamic> toJson() => {
    'id': id,
    'myUserId': myUserId,
    'friendUserId': friendUserId,
    'friendName': friendName,
    'friendAvatar': friendAvatar,
    'mySteps': mySteps,
    'friendSteps': friendSteps,
    'myWater': myWater,
    'friendWater': friendWater,
    'mySleep': mySleep,
    'friendSleep': friendSleep,
    'myPoints': myPoints,
    'friendPoints': friendPoints,
    'date': date.toIso8601String(),
  };
}

FriendCompetition friendCompetitionFromJson(Map<String, dynamic> json) => FriendCompetition(
  id: json['id'] as String,
  myUserId: json['myUserId'] as int,
  friendUserId: json['friendUserId'] as int,
  friendName: json['friendName'] as String,
  friendAvatar: json['friendAvatar'] as String?,
  mySteps: json['mySteps'] as int,
  friendSteps: json['friendSteps'] as int,
  myWater: json['myWater'] as int,
  friendWater: json['friendWater'] as int,
  mySleep: json['mySleep'] as int,
  friendSleep: json['friendSleep'] as int,
  myPoints: json['myPoints'] as int,
  friendPoints: json['friendPoints'] as int,
  date: DateTime.parse(json['date'] as String),
);

