import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        // store relation as a code for localization-agnostic persistence
        'relation': _normalizeRelationCode(invitation['relation'] as String? ?? 'other'),
        'is_real_user': true,
      });
    }
    
    // To user'ın aile listesine from user'ı ekle  
    Map<String, dynamic>? fromUser = await getUserById(fromUserId);
    if (fromUser != null) {
      String reverseRelation = _getReverseRelationCode(invitation['relation'] as String? ?? 'other');
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

  // Normalize human-readable (possibly localized) relation strings to codes
  String _normalizeRelationCode(String relation) {
    // Map known Turkish labels to codes; fallback to provided code if already code-like
    const Map<String, String> trToCode = {
      'Baba': 'father',
      'Anne': 'mother',
      'Çocuk': 'child',
      'Eş': 'spouse',
      'Kardeş': 'sibling',
      'Büyükbaba': 'grandfather',
      'Büyükanne': 'grandmother',
      'Torun': 'grandchild',
      'Aile Üyesi': 'other',
    };
    final lower = relation.trim();
    if (trToCode.containsKey(lower)) return trToCode[lower]!;
    // If it already looks like a code we support, keep it
    const allowed = {
      'father','mother','child','spouse','sibling','grandfather','grandmother','grandchild','other'
    };
    return allowed.contains(lower) ? lower : 'other';
  }

  // Given a relation (localized or code), return reverse relation code
  String _getReverseRelationCode(String relation) {
    final code = _normalizeRelationCode(relation);
    const Map<String, String> reverse = {
      'father': 'child',
      'mother': 'child',
      'child': 'parent', // map to parent generic; will display localized label accordingly
      'spouse': 'spouse',
      'sibling': 'sibling',
      'grandfather': 'grandchild',
      'grandmother': 'grandchild',
      'grandchild': 'grandparent',
      'other': 'other',
      'parent': 'child',
      'grandparent': 'grandchild',
    };
    return reverse[code] ?? 'other';
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

  // Hatırlatıcılar (Reminders)
  Future<int> createReminder(Map<String, dynamic> reminder) async {
    try {
      if (_prefs == null) await init();
      final int userId = reminder['user_id'] as int;
      // Load existing reminders for user
      String? data = _prefs!.getString('reminders_$userId');
      List<Map<String, dynamic>> reminders = [];
      if (data != null && data.isNotEmpty) {
        reminders = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      }

      // Assign ID
      int newId = DateTime.now().millisecondsSinceEpoch;
      reminder['id'] = newId;
      reminder['created_at'] = DateTime.now().toIso8601String();
      reminder['updated_at'] = DateTime.now().toIso8601String();

      reminders.insert(0, reminder);
      await _prefs!.setString('reminders_$userId', jsonEncode(reminders));
      return newId;
    } catch (e) {
      print('Hatırlatıcı oluşturma hatası: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getReminders(int userId) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('reminders_$userId');
      if (data != null) {
        List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Hatırlatıcı listesi yükleme hatası: $e');
      return [];
    }
  }

  Future<int> updateReminderStatus(int userId, int reminderId, bool isActive) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('reminders_$userId');
      if (data == null) return 0;
      List<Map<String, dynamic>> reminders = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      bool updated = false;
      for (int i = 0; i < reminders.length; i++) {
        if (reminders[i]['id'] == reminderId) {
          reminders[i]['is_active'] = isActive;
          reminders[i]['updated_at'] = DateTime.now().toIso8601String();
          updated = true;
          break;
        }
      }
      if (!updated) return 0;
      await _prefs!.setString('reminders_$userId', jsonEncode(reminders));
      return 1;
    } catch (e) {
      print('Hatırlatıcı durumu güncelleme hatası: $e');
      return 0;
    }
  }

  Future<int> deleteReminder(int userId, int reminderId) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('reminders_$userId');
      if (data == null) return 0;
      List<Map<String, dynamic>> reminders = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      int before = reminders.length;
      reminders.removeWhere((r) => r['id'] == reminderId);
      if (reminders.length == before) return 0;
      await _prefs!.setString('reminders_$userId', jsonEncode(reminders));
      return 1;
    } catch (e) {
      print('Hatırlatıcı silme hatası: $e');
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



  // Advanced Analytics metodları
  Future<List<Map<String, dynamic>>> getHemogramTestsByUser(int userId) async {
    try {
      String? data = _prefs!.getString('hemogram_tests');
      if (data != null) {
        List<Map<String, dynamic>> tests = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
        return tests.where((test) => test['user_id'] == userId).toList();
      }
      return [];
    } catch (e) {
      print('Hemogram testleri yükleme hatası: $e');
      return [];
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