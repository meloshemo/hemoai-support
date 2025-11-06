import 'package:flutter/foundation.dart';

import '../services/database_helper.dart';
import '../services/web_database_helper.dart';

/// Repository for Reminders and their streak/logs.
class ReminderRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final WebDatabaseHelper _web = WebDatabaseHelper.instance;

  // ---- Reminders CRUD ----
  Future<int> createReminder(Map<String, dynamic> reminder) async {
    if (kIsWeb) {
      return await _web.createReminder(reminder);
    }
    return await _db.createReminder(reminder);
  }

  Future<List<Map<String, dynamic>>> getReminders(int userId) async {
    if (kIsWeb) {
      return await _web.getReminders(userId);
    }
    // Native path supports filtering by userId
    return await _db.getAllReminders(userId);
  }

  Future<int> setReminderActive({
    required int userId,
    required int reminderId,
    required bool isActive,
  }) async {
    if (kIsWeb) {
      return await _web.updateReminderStatus(userId, reminderId, isActive);
    }
    return await _db.updateReminder(reminderId, {'is_active': isActive ? 1 : 0});
  }

  Future<int> deleteReminder({
    required int userId,
    required int reminderId,
  }) async {
    if (kIsWeb) {
      return await _web.deleteReminder(userId, reminderId);
    }
    return await _db.deleteReminder(reminderId);
  }

  // ---- Streaks & Logs (both backends are bridged by DatabaseHelper) ----
  Future<Map<String, dynamic>> getReminderStreak(int reminderId, {int? userId}) {
    return _db.getReminderStreak(reminderId, userId: userId);
  }

  Future<int> upsertReminderStreak({
    required int reminderId,
    int? userId,
    required int currentStreak,
    required int longestStreak,
    String? lastCompletedDate,
  }) {
    return _db.upsertReminderStreak(
      reminderId: reminderId,
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletedDate: lastCompletedDate,
    );
  }

  Future<int> insertReminderLog({
    required int reminderId,
    int? userId,
    required String action,
    required DateTime actionDate,
    DateTime? scheduledTime,
    String? metadata,
  }) {
    return _db.insertReminderLog(
      reminderId: reminderId,
      userId: userId,
      action: action,
      actionDate: actionDate,
      scheduledTime: scheduledTime,
      metadata: metadata,
    );
  }
}
