import 'package:flutter/foundation.dart';

import '../services/database_helper.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';

/// Single Source of Truth for User-related operations.
/// Routes calls to the appropriate backend (web prefs-backed DB or native SQL) and
/// centralizes active-user state via PreferencesService.
class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final WebDatabaseHelper _web = WebDatabaseHelper.instance;

  // ---- Active user helpers ----
  Future<void> setActiveUserId(int id) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setCurrentUserId(id);
  }

  Future<int?> getActiveUserId() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getCurrentUserId();
  }

  // ---- CRUD ----
  Future<int> createUser(Map<String, dynamic> user) async {
    if (kIsWeb) {
      return await _web.insertUser(user);
    }
    return await _db.insertUser(user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (kIsWeb) {
      return await _web.getUser(email);
    }
    return await _db.getUser(email);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    if (kIsWeb) {
      return await _web.getUserById(id);
    }
    return await _db.getUserById(id);
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    if (kIsWeb) {
      return await _web.updateUser(id, user);
    }
    return await _db.updateUser(id, user);
  }

  // ---- Stats ----
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final raw = kIsWeb
        ? await _web.getUserStats(userId)
        : await _db.getUserStats(userId);
    // Normalize keys to a consistent camelCase shape for consumers/tests
    return {
      'totalTests': raw['totalTests'] ?? raw['total_tests'] ?? 0,
      'familyMembers': raw['familyMembers'] ?? raw['family_members'] ?? 0,
      'activeMedications': raw['activeMedications'] ?? raw['active_medications'] ?? 0,
      'unreadNotifications': raw['unreadNotifications'] ?? raw['unread_notifications'] ?? 0,
    };
  }
}
