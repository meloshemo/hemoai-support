import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

/// NotificationRepository provides a single-source-of-truth access layer
/// for notifications across web (SharedPreferences) and native (sqflite).
class NotificationRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    try {
      return await _db.getNotifications(userId);
    } catch (e) {
      debugPrint('NotificationRepository.getNotifications error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<int> createNotification({
    required int userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      return await _db.createNotification(userId, title, message, type);
    } catch (e) {
      debugPrint('NotificationRepository.createNotification error: $e');
      return 0;
    }
  }

  Future<int> markAsRead(int id) async {
    try {
      return await _db.markNotificationAsRead(id);
    } catch (e) {
      debugPrint('NotificationRepository.markAsRead error: $e');
      return 0;
    }
  }

  Future<int> delete(int id) async {
    try {
      return await _db.deleteNotification(id);
    } catch (e) {
      debugPrint('NotificationRepository.delete error: $e');
      return 0;
    }
  }
}
