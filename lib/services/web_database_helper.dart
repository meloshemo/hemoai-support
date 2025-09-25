import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WebDatabaseHelper {
  static WebDatabaseHelper? _instance;
  SharedPreferences? _prefs;

  WebDatabaseHelper._internal();
  
  static WebDatabaseHelper get instance {
    _instance ??= WebDatabaseHelper._internal();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Kullanıcı işlemleri
  Future<int> insertUser(Map<String, dynamic> user) async {
    if (_prefs == null) await init();
    
    // Unique ID oluştur
    int userId = DateTime.now().millisecondsSinceEpoch;
    user['id'] = userId;
    user['created_at'] = DateTime.now().toIso8601String();
    user['updated_at'] = DateTime.now().toIso8601String();
    
    // Kullanıcıları kaydet
    List<String> users = _prefs!.getStringList('users') ?? [];
    users.add(json.encode(user));
    await _prefs!.setStringList('users', users);
    
    return userId;
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    if (_prefs == null) await init();
    
    List<String> users = _prefs!.getStringList('users') ?? [];
    
    for (String userStr in users) {
      Map<String, dynamic> user = json.decode(userStr);
      if (user['email'] == email) {
        return user;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    if (_prefs == null) await init();
    
    List<String> users = _prefs!.getStringList('users') ?? [];
    
    for (String userStr in users) {
      Map<String, dynamic> user = json.decode(userStr);
      if (user['id'] == id) {
        return user;
      }
    }
    return null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> userData) async {
    if (_prefs == null) await init();
    
    List<String> users = _prefs!.getStringList('users') ?? [];
    List<String> updatedUsers = [];
    
    for (String userStr in users) {
      Map<String, dynamic> user = json.decode(userStr);
      if (user['id'] == id) {
        user.addAll(userData);
        user['updated_at'] = DateTime.now().toIso8601String();
      }
      updatedUsers.add(json.encode(user));
    }
    
    await _prefs!.setStringList('users', updatedUsers);
    return 1;
  }

  // Hemogram testleri
  Future<int> insertHemogramTest(Map<String, dynamic> test) async {
    if (_prefs == null) await init();
    
    int testId = DateTime.now().millisecondsSinceEpoch;
    test['id'] = testId;
    test['created_at'] = DateTime.now().toIso8601String();
    
    List<String> tests = _prefs!.getStringList('hemogram_tests') ?? [];
    tests.add(json.encode(test));
    await _prefs!.setStringList('hemogram_tests', tests);
    
    return testId;
  }

  Future<List<Map<String, dynamic>>> getHemogramTests(int userId) async {
    if (_prefs == null) await init();
    
    List<String> tests = _prefs!.getStringList('hemogram_tests') ?? [];
    List<Map<String, dynamic>> userTests = [];
    
    for (String testStr in tests) {
      Map<String, dynamic> test = json.decode(testStr);
      if (test['user_id'] == userId) {
        userTests.add(test);
      }
    }
    
    // Tarihe göre sırala (yeniden eskiye)
    userTests.sort((a, b) => b['test_date'].compareTo(a['test_date']));
    return userTests;
  }

  Future<Map<String, dynamic>?> getLatestHemogramTest(int userId) async {
    List<Map<String, dynamic>> tests = await getHemogramTests(userId);
    return tests.isNotEmpty ? tests.first : null;
  }

  // Aile üyeleri
  Future<int> insertFamilyMember(Map<String, dynamic> member) async {
    if (_prefs == null) await init();
    
    int memberId = DateTime.now().millisecondsSinceEpoch;
    member['id'] = memberId;
    member['created_at'] = DateTime.now().toIso8601String();
    
    List<String> members = _prefs!.getStringList('family_members') ?? [];
    members.add(json.encode(member));
    await _prefs!.setStringList('family_members', members);
    
    return memberId;
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(int userId) async {
    if (_prefs == null) await init();
    
    List<String> members = _prefs!.getStringList('family_members') ?? [];
    List<Map<String, dynamic>> userMembers = [];
    
    for (String memberStr in members) {
      Map<String, dynamic> member = json.decode(memberStr);
      if (member['user_id'] == userId) {
        userMembers.add(member);
      }
    }
    
    return userMembers;
  }

  Future<int> updateFamilyMember(int id, Map<String, dynamic> memberData) async {
    if (_prefs == null) await init();
    
    List<String> members = _prefs!.getStringList('family_members') ?? [];
    List<String> updatedMembers = [];
    
    for (String memberStr in members) {
      Map<String, dynamic> member = json.decode(memberStr);
      if (member['id'] == id) {
        member.addAll(memberData);
        member['updated_at'] = DateTime.now().toIso8601String();
      }
      updatedMembers.add(json.encode(member));
    }
    
    await _prefs!.setStringList('family_members', updatedMembers);
    return 1;
  }

  Future<int> deleteFamilyMember(int id) async {
    if (_prefs == null) await init();
    
    List<String> members = _prefs!.getStringList('family_members') ?? [];
    List<String> filteredMembers = [];
    
    for (String memberStr in members) {
      Map<String, dynamic> member = json.decode(memberStr);
      if (member['id'] != id) {
        filteredMembers.add(memberStr);
      }
    }
    
    await _prefs!.setStringList('family_members', filteredMembers);
    return 1;
  }

  // Basit istatistikler
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    List<Map<String, dynamic>> tests = await getHemogramTests(userId);
    List<Map<String, dynamic>> family = await getFamilyMembers(userId);
    
    return {
      'total_tests': tests.length,
      'family_members': family.length,
      'active_medications': 0,
      'unread_notifications': 0,
    };
  }

  // Davet sistemi
  Future<int> sendFamilyInvitation(Map<String, dynamic> invitation) async {
    if (_prefs == null) await init();
    
    int invitationId = DateTime.now().millisecondsSinceEpoch;
    invitation['id'] = invitationId;
    invitation['created_at'] = DateTime.now().toIso8601String();
    invitation['status'] = 'pending'; // pending, accepted, rejected
    
    List<String> invitations = _prefs!.getStringList('family_invitations') ?? [];
    invitations.add(json.encode(invitation));
    await _prefs!.setStringList('family_invitations', invitations);
    
    return invitationId;
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(int userId) async {
    if (_prefs == null) await init();
    
    List<String> invitations = _prefs!.getStringList('family_invitations') ?? [];
    List<Map<String, dynamic>> userInvitations = [];
    
    for (String invitationStr in invitations) {
      Map<String, dynamic> invitation = json.decode(invitationStr);
      if (invitation['to_user_id'] == userId && invitation['status'] == 'pending') {
        userInvitations.add(invitation);
      }
    }
    
    return userInvitations;
  }

  Future<int> respondToInvitation(int invitationId, String response) async {
    if (_prefs == null) await init();
    
    List<String> invitations = _prefs!.getStringList('family_invitations') ?? [];
    List<String> updatedInvitations = [];
    
    for (String invitationStr in invitations) {
      Map<String, dynamic> invitation = json.decode(invitationStr);
      if (invitation['id'] == invitationId) {
        invitation['status'] = response; // 'accepted' or 'rejected'
        invitation['responded_at'] = DateTime.now().toIso8601String();
        
        // Eğer kabul edildiyse, aile üyesi olarak ekle
        if (response == 'accepted') {
          await _addFamilyConnection(invitation);
        }
      }
      updatedInvitations.add(json.encode(invitation));
    }
    
    await _prefs!.setStringList('family_invitations', updatedInvitations);
    return 1;
  }

  Future<void> _addFamilyConnection(Map<String, dynamic> invitation) async {
    // Çift yönlü bağlantı oluştur
    int fromUserId = invitation['from_user_id'];
    int toUserId = invitation['to_user_id'];
    
    // From user'ın aile listesine to user'ı ekle
    Map<String, dynamic>? toUser = await getUserById(toUserId);
    if (toUser != null) {
      await insertFamilyMember({
        'user_id': fromUserId,
        'connected_user_id': toUserId,
        'name': toUser['name'],
        'phone': toUser['phone'],
        'relation': invitation['relation'] ?? 'Aile Üyesi',
        'is_real_user': true,
      });
    }
    
    // To user'ın aile listesine from user'ı ekle  
    Map<String, dynamic>? fromUser = await getUserById(fromUserId);
    if (fromUser != null) {
      String reverseRelation = _getReverseRelation(invitation['relation'] ?? 'Aile Üyesi');
      await insertFamilyMember({
        'user_id': toUserId,
        'connected_user_id': fromUserId,
        'name': fromUser['name'],
        'phone': fromUser['phone'],
        'relation': reverseRelation,
        'is_real_user': true,
      });
    }
  }

  String _getReverseRelation(String relation) {
    Map<String, String> reverseMap = {
      'Baba': 'Çocuk',
      'Anne': 'Çocuk', 
      'Çocuk': 'Ebeveyn',
      'Eş': 'Eş',
      'Kardeş': 'Kardeş',
      'Büyükbaba': 'Torun',
      'Büyükanne': 'Torun',
      'Torun': 'Büyükbaba', // Varsayılan
    };
    return reverseMap[relation] ?? 'Aile Üyesi';
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    if (_prefs == null) await init();
    
    String email = '$phone@hemoai.com';
    return await getUser(email);
  }

  // İlaç yönetimi
  Future<int> addMedication(int userId, String name, String dosage, String frequency, String time) async {
    try {
      List<Map<String, dynamic>> medications = await getMedications(userId);
      int newId = medications.length + 1;
      
      Map<String, dynamic> medication = {
        'id': newId,
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'time': time,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      medications.add(medication);
      await _prefs!.setString('medications_$userId', jsonEncode(medications));
      return newId;
    } catch (e) {
      print('İlaç ekleme hatası: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getMedications(int userId) async {
    try {
      String? data = _prefs!.getString('medications_$userId');
      if (data != null) {
        List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('İlaç listesi yükleme hatası: $e');
      return [];
    }
  }

  Future<int> updateMedicationStatus(int medicationId, bool isActive) async {
    try {
      // Tüm kullanıcıların ilaçlarını kontrol et
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith('medications_')) {
          String? data = _prefs!.getString(key);
          if (data != null) {
            List<Map<String, dynamic>> medications = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
            for (int i = 0; i < medications.length; i++) {
              if (medications[i]['id'] == medicationId) {
                medications[i]['is_active'] = isActive;
                await _prefs!.setString(key, jsonEncode(medications));
                return 1;
              }
            }
          }
        }
      }
      return 0;
    } catch (e) {
      print('İlaç durumu güncelleme hatası: $e');
      return 0;
    }
  }

  // Bildirim yönetimi
  Future<int> createNotification(int userId, String title, String message, String type) async {
    try {
      List<Map<String, dynamic>> notifications = await getNotifications(userId);
      int newId = notifications.length + 1;
      
      Map<String, dynamic> notification = {
        'id': newId,
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      notifications.insert(0, notification); // En başa ekle
      await _prefs!.setString('notifications_$userId', jsonEncode(notifications));
      return newId;
    } catch (e) {
      print('Bildirim oluşturma hatası: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    try {
      String? data = _prefs!.getString('notifications_$userId');
      if (data != null) {
        List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Bildirim listesi yükleme hatası: $e');
      return [];
    }
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    try {
      // Tüm kullanıcıların bildirimlerini kontrol et
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith('notifications_')) {
          String? data = _prefs!.getString(key);
          if (data != null) {
            List<Map<String, dynamic>> notifications = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
            for (int i = 0; i < notifications.length; i++) {
              if (notifications[i]['id'] == notificationId) {
                notifications[i]['is_read'] = true;
                await _prefs!.setString(key, jsonEncode(notifications));
                return 1;
              }
            }
          }
        }
      }
      return 0;
    } catch (e) {
      print('Bildirim okundu işaretleme hatası: $e');
      return 0;
    }
  }

  Future<int> deleteNotification(int notificationId) async {
    try {
      // Tüm kullanıcıların bildirimlerini kontrol et
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith('notifications_')) {
          String? data = _prefs!.getString(key);
          if (data != null) {
            List<Map<String, dynamic>> notifications = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
            notifications.removeWhere((n) => n['id'] == notificationId);
            await _prefs!.setString(key, jsonEncode(notifications));
            return 1;
          }
        }
      }
      return 0;
    } catch (e) {
      print('Bildirim silme hatası: $e');
      return 0;
    }
  }

  // Su takibi
  Future<int> logWaterIntake(int userId, int glassCount) async {
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      await _prefs!.setInt('water_${userId}_$today', glassCount);
      return 1;
    } catch (e) {
      print('Su takibi kaydetme hatası: $e');
      return 0;
    }
  }

  Future<int> getTodayWaterIntake(int userId) async {
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      return _prefs!.getInt('water_${userId}_$today') ?? 0;
    } catch (e) {
      print('Su takibi yükleme hatası: $e');
      return 0;
    }
  }

  Future<int> createNotification(int userId, String title, String message, String type) async {
    try {
      String key = 'notifications_$userId';
      String? data = _prefs!.getString(key);
      
      List<Map<String, dynamic>> notifications = [];
      if (data != null) {
        notifications = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      }
      
      int newId = DateTime.now().millisecondsSinceEpoch;
      
      Map<String, dynamic> newNotification = {
        'id': newId,
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      notifications.add(newNotification);
      await _prefs!.setString(key, jsonEncode(notifications));
      
      return newId;
    } catch (e) {
      print('Bildirim oluşturma hatası: $e');
      return 0;
    }
  }

  // Veritabanını temizle
  Future<void> clearDatabase() async {
    if (_prefs == null) await init();
    
    await _prefs!.remove('users');
    await _prefs!.remove('hemogram_tests');
    await _prefs!.remove('family_members');
    await _prefs!.remove('family_invitations');
  }
}