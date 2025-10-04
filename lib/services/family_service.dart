import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'web_database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final WebDatabaseHelper _web = WebDatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getFamilyMembers(int userId) async {
    if (kIsWeb) {
      await _web.init();
      return _web.getFamilyMembers(userId);
    }
    // Native path
    final members = await _db.getFamilyMembers(userId);
    if (members.isNotEmpty) return members;
    // Migration: Previously, some family members might have been saved into SharedPreferences on native.
    // Import those entries once into the native DB.
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('family_members');
    if (list == null || list.isEmpty) return members;
    final decoded = list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    final toImport = decoded.where((m) => (m['user_id'] is int ? m['user_id'] as int : null) == userId).toList();
    if (toImport.isEmpty) return members;
    for (final m in toImport) {
      // Remove legacy id to avoid conflicts; DB will autoincrement
      m.remove('id');
      await _db.insertFamilyMember(m);
    }
    // Keep SP entries for other users, drop migrated ones
    final remaining = decoded.where((m) => m['user_id'] != userId).map((m) => jsonEncode(m)).toList();
    await prefs.setStringList('family_members', remaining);
    // Return fresh list from DB
    return _db.getFamilyMembers(userId);
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(int userId) async {
    if (kIsWeb) {
      await _web.init();
      return _web.getPendingInvitations(userId);
    }
    return _db.getPendingInvitations(userId);
  }

  // CRUD operations for family members
  Future<int> insertFamilyMember(Map<String, dynamic> member) async {
    if (kIsWeb) {
      await _web.init();
      return _web.insertFamilyMember(member);
    }
    return _db.insertFamilyMember(member);
  }

  Future<int> updateFamilyMember(int id, Map<String, dynamic> member) async {
    if (kIsWeb) {
      await _web.init();
      return _web.updateFamilyMember(id, member);
    }
    return _db.updateFamilyMember(id, member);
  }

  Future<int> deleteFamilyMember(int id) async {
    if (kIsWeb) {
      await _web.init();
      return _web.deleteFamilyMember(id);
    }
    return _db.deleteFamilyMember(id);
  }

  // Invitations
  Future<int> sendFamilyInvitation(Map<String, dynamic> invitation) async {
    if (kIsWeb) {
      await _web.init();
      return _web.sendFamilyInvitation(invitation);
    }
    return _db.sendFamilyInvitation(invitation);
  }

  Future<int> respondToInvitation(int invitationId, String response) async {
    if (kIsWeb) {
      await _web.init();
      return _web.respondToInvitation(invitationId, response);
    }
    return _db.respondToInvitation(invitationId, response);
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    if (kIsWeb) {
      await _web.init();
      return _web.findUserByPhone(phone);
    }
    return _db.findUserByPhone(phone);
  }

  Future<Map<String, dynamic>?> getLatestHemogramForConnected(int? connectedUserId) async {
    if (connectedUserId == null) return null;
    if (kIsWeb) {
      await _web.init();
      return _web.getLatestHemogramTest(connectedUserId);
    }
    return _db.getLatestHemogramTest(connectedUserId);
  }

  Future<List<int>> getLast7DaysWaterForConnected(int? connectedUserId) async {
    if (connectedUserId == null) return const <int>[];
    if (kIsWeb) {
      await _web.init();
      return _web.getLast7DaysWaterIntake(connectedUserId);
    }
    return _db.getLast7DaysWaterIntake(connectedUserId);
  }

  Future<void> addWaterGlassForConnected(int? connectedUserId) async {
    if (connectedUserId == null) return;
    if (kIsWeb) {
      await _web.init();
      final today = await _web.getTodayWaterIntake(connectedUserId);
      await _web.logWaterIntake(connectedUserId, today + 1);
    } else {
      final today = await _db.getTodayWaterIntake(connectedUserId);
      await _db.logWaterIntake(connectedUserId, today + 1);
    }
  }

  Future<Map<String, dynamic>> computeStats(int userId, List<Map<String, dynamic>> members, List<Map<String, dynamic>> invites) async {
    // Aggregate: members count, pending invites, average family water (connected only), latest tests count
    int connectedCount = 0;
    int latestTests = 0;
    int waterSum = 0;
    int waterSamples = 0;
    for (final m in members) {
      final int? connectedUserId = m['connected_user_id'] is int ? m['connected_user_id'] as int : null;
      if (connectedUserId != null) {
        connectedCount++;
        final latest = await getLatestHemogramForConnected(connectedUserId);
        if (latest != null) {
          latestTests++;
        }
        final last7 = await getLast7DaysWaterForConnected(connectedUserId);
        if (last7.isNotEmpty) {
          waterSum += last7.fold(0, (a, b) => a + b);
          waterSamples += last7.length;
        }
      }
    }
    final double avg = waterSamples > 0 ? waterSum / waterSamples : 0.0;
    return {
      'members_count': members.length,
      'pending_invites': invites.length,
      'connected_count': connectedCount,
      'water_avg_7d': avg,
      'latest_tests_with_data': latestTests,
    };
  }

  Future<List<Map<String, dynamic>>> buildWaterLeaderboard(List<Map<String, dynamic>> members) async {
    final List<Map<String, dynamic>> items = [];
    for (final m in members) {
      final int? connectedUserId = m['connected_user_id'] is int ? m['connected_user_id'] as int : null;
      if (connectedUserId != null) {
        final last7 = await getLast7DaysWaterForConnected(connectedUserId);
        final total = last7.fold(0, (a, b) => a + b);
        items.add({
          'member': m,
          'total': total,
        });
      }
    }
    items.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return items;
  }
}
