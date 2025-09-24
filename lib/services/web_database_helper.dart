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

  // Veritabanını temizle
  Future<void> clearDatabase() async {
    if (_prefs == null) await init();
    
    await _prefs!.remove('users');
    await _prefs!.remove('hemogram_tests');
    await _prefs!.remove('family_members');
  }
}