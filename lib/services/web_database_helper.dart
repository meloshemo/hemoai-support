import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class WebDatabaseHelper {
  static WebDatabaseHelper? _instance;
  SharedPreferences? _prefs;

  WebDatabaseHelper._internal();

  int _boolToInt(dynamic value, {int defaultValue = 0}) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value != 0 ? 1 : 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return 1;
      if (normalized == 'false' || normalized == '0') return 0;
    }
    return defaultValue;
  }

  static WebDatabaseHelper get instance {
    _instance ??= WebDatabaseHelper._internal();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    if (_prefs == null) await init();

    // Generate unique ID
    int userId = DateTime.now().millisecondsSinceEpoch;
    user['id'] = userId;
    user['created_at'] = DateTime.now().toIso8601String();
    user['updated_at'] = DateTime.now().toIso8601String();
    user['email_verified'] =
        _boolToInt(user['email_verified'], defaultValue: 0);
    user['phone_verified'] =
        _boolToInt(user['phone_verified'], defaultValue: 0);

    // Persist users
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
      user.putIfAbsent('email_verified', () => 0);
      user.putIfAbsent('phone_verified', () => 0);
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
      user.putIfAbsent('email_verified', () => 0);
      user.putIfAbsent('phone_verified', () => 0);
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
        user['email_verified'] =
            _boolToInt(user['email_verified'], defaultValue: 0);
        user['phone_verified'] =
            _boolToInt(user['phone_verified'], defaultValue: 0);
      } else {
        user.putIfAbsent('email_verified', () => 0);
        user.putIfAbsent('phone_verified', () => 0);
      }
      updatedUsers.add(json.encode(user));
    }

    await _prefs!.setStringList('users', updatedUsers);
    return 1;
  }

  // Hemogram testleri
  Future<int> insertHemogramTest(Map<String, dynamic> test) async {
    if (_prefs == null) await init();
    final nowIso = DateTime.now().toIso8601String();
    final int testId = DateTime.now().millisecondsSinceEpoch;
    final int? userId = (test['user_id'] as num?)?.toInt();
    test['id'] = testId;
    test['created_at'] = test['created_at'] ?? nowIso;

    String status =
        (test['status'] ?? 'active').toString().toLowerCase().trim();
    if (status != 'archived') {
      status = 'active';
    }

    final tests = await _loadAllHemogramTests();
    Map<String, dynamic>? currentActive;
    if (userId != null) {
      for (final existing in tests) {
        final existingUserId = (existing['user_id'] as num?)?.toInt();
        final existingStatus =
            (existing['status'] ?? 'active').toString().toLowerCase().trim();
        if (existingUserId == userId && existingStatus == 'active') {
          currentActive = existing;
          break;
        }
      }
    }

    DateTime? newTestDate;
    final rawTestDate = test['test_date'];
    if (rawTestDate is String && rawTestDate.isNotEmpty) {
      newTestDate = DateTime.tryParse(rawTestDate);
    }

    if (userId != null &&
        status == 'active' &&
        currentActive != null &&
        newTestDate != null) {
      final currentDate = DateTime.tryParse(
        (currentActive['test_date'] ?? '') as String,
      );
      if (currentDate != null && newTestDate.isBefore(currentDate)) {
        status = 'archived';
      }
    }

    if (status == 'archived') {
      test['status'] = 'archived';
      test['archived_at'] = test['archived_at'] ?? nowIso;
    } else {
      test['status'] = 'active';
      test.remove('archived_at');
    }

    if (userId != null && status == 'active') {
      bool mutated = false;
      for (final existing in tests) {
        final existingUserId = (existing['user_id'] as num?)?.toInt();
        if (existingUserId == userId &&
            (existing['status'] == 'active' || existing['status'] == null)) {
          existing['status'] = 'archived';
          existing['archived_at'] =
              existing['archived_at'] ?? existing['created_at'] ?? nowIso;
          mutated = true;
        }
      }
      if (mutated) {
        await _persistHemogramTests(tests);
      }
    }

    tests.add(test);
    await _persistHemogramTests(tests);

    return testId;
  }

  Future<List<Map<String, dynamic>>> getHemogramTests(int userId) async {
    if (_prefs == null) await init();
    final allTests = await _loadAllHemogramTests();
    final userTests = allTests
        .where((test) => (test['user_id'] as num?)?.toInt() == userId)
        .map((test) => Map<String, dynamic>.from(test))
        .toList();

    userTests.sort((a, b) {
      final aDate = (a['test_date'] ?? '') as String;
      final bDate = (b['test_date'] ?? '') as String;
      return bDate.compareTo(aDate);
    });

    final bool changed =
        _normalizeUserHemogramStatuses(userId, allTests, userTests);
    if (changed) {
      await _persistHemogramTests(allTests);
    }

    return userTests;
  }

  Future<Map<String, dynamic>?> getLatestHemogramTest(int userId) async {
    return await getActiveHemogramTest(userId);
  }

  // Family members
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

  Future<int> updateFamilyMember(
      int id, Map<String, dynamic> memberData) async {
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

    List<String> invitations =
        _prefs!.getStringList('family_invitations') ?? [];
    invitations.add(json.encode(invitation));
    await _prefs!.setStringList('family_invitations', invitations);

    return invitationId;
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(int userId) async {
    if (_prefs == null) await init();

    List<String> invitations =
        _prefs!.getStringList('family_invitations') ?? [];
    List<Map<String, dynamic>> userInvitations = [];

    for (String invitationStr in invitations) {
      Map<String, dynamic> invitation = json.decode(invitationStr);
      if (invitation['to_user_id'] == userId &&
          invitation['status'] == 'pending') {
        userInvitations.add(invitation);
      }
    }

    return userInvitations;
  }

  Future<int> respondToInvitation(int invitationId, String response) async {
    if (_prefs == null) await init();

    List<String> invitations =
        _prefs!.getStringList('family_invitations') ?? [];
    List<String> updatedInvitations = [];

    for (String invitationStr in invitations) {
      Map<String, dynamic> invitation = json.decode(invitationStr);
      if (invitation['id'] == invitationId) {
        invitation['status'] = response; // 'accepted' or 'rejected'
        invitation['responded_at'] = DateTime.now().toIso8601String();

        // If accepted, add as a family connection
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
    // Create a bi-directional connection
    int fromUserId = invitation['from_user_id'];
    int toUserId = invitation['to_user_id'];

    // From user's family list add the other user
    Map<String, dynamic>? toUser = await getUserById(toUserId);
    if (toUser != null) {
      await insertFamilyMember({
        'user_id': fromUserId,
        'connected_user_id': toUserId,
        'name': toUser['name'],
        'phone': toUser['phone'],
        // store relation as a code for localization-agnostic persistence
        'relation': _normalizeRelationCode(
            invitation['relation'] as String? ?? 'other'),
        'is_real_user': true,
      });
    }

    // To user's family list add the from user
    Map<String, dynamic>? fromUser = await getUserById(fromUserId);
    if (fromUser != null) {
      String reverseRelation =
          _getReverseRelationCode(invitation['relation'] as String? ?? 'other');
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
    // Accept canonical codes directly
    const allowed = {
      'father',
      'mother',
      'child',
      'spouse',
      'sibling',
      'grandfather',
      'grandmother',
      'grandchild',
      'parent',
      'grandparent',
      'other'
    };
    final raw = relation.trim();
    if (allowed.contains(raw)) return raw;

    // Diacritic-insensitive normalization for some common inputs (ASCII only here)
    String ascii = raw
        .toLowerCase()
        .replaceAll('\u0131', 'i') // i-dotless
        .replaceAll('\u011f', 'g') // g-breve
        .replaceAll('\u015f', 's') // s-cedilla
        .replaceAll('\u00f6', 'o') // o-umlaut
        .replaceAll('\u00e7', 'c') // c-cedilla
        .replaceAll('\u00fc', 'u') // u-umlaut
        .replaceAll('\u00e2', 'a') // a-circumflex
        .replaceAll('\u00ee', 'i') // i-circumflex
        .replaceAll('\u00fb', 'u'); // u-circumflex

    switch (ascii) {
      case 'baba':
        return 'father';
      case 'anne':
        return 'mother';
      case 'cocuk':
        return 'child';
      case 'es':
        return 'spouse';
      case 'kardes':
        return 'sibling';
      case 'buyukbaba':
        return 'grandfather';
      case 'buyukanne':
        return 'grandmother';
      case 'torun':
        return 'grandchild';
      case 'aile uyesi':
        return 'other';
      default:
        return allowed.contains(ascii) ? ascii : 'other';
    }
  }

  // Given a relation (localized or code), return reverse relation code
  String _getReverseRelationCode(String relation) {
    final code = _normalizeRelationCode(relation);
    const Map<String, String> reverse = {
      'father': 'child',
      'mother': 'child',
      'child':
          'parent', // map to parent generic; will display localized label accordingly
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

    // Normalize the input phone: remove all non-digit characters
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');

    final users = _prefs!.getStringList('users') ?? [];
    for (final userStr in users) {
      final user = Map<String, dynamic>.from(json.decode(userStr));
      // Ensure required fields exist
      if (!user.containsKey('id') || user['id'] == null) {
        // Generate a fallback ID if missing (shouldn't happen, but safety check)
        user['id'] = DateTime.now().millisecondsSinceEpoch;
      }
      user.putIfAbsent('phone', () => '');
      user.putIfAbsent('email_verified', () => 0);
      user.putIfAbsent('phone_verified', () => 0);
      
      final storedPhone = (user['phone'] ?? '').toString();
      // Try exact match first
      if (storedPhone == phone) {
        return user;
      }
      // Try normalized match
      final normalizedStored = storedPhone.replaceAll(RegExp(r'\D'), '');
      if (normalizedStored == normalizedPhone && normalizedPhone.isNotEmpty) {
        return user;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _loadAllHemogramTests() async {
    if (_prefs == null) await init();
    final raw = _prefs!.getStringList('hemogram_tests') ?? [];
    return raw
        .map((entry) => Map<String, dynamic>.from(json.decode(entry)))
        .toList();
  }

  Future<void> _persistHemogramTests(List<Map<String, dynamic>> tests) async {
    final encoded = tests.map((test) => json.encode(test)).toList();
    await _prefs!.setStringList('hemogram_tests', encoded);
  }

  bool _normalizeUserHemogramStatuses(
    int userId,
    List<Map<String, dynamic>> allTests,
    List<Map<String, dynamic>> userTests,
  ) {
    bool changed = false;
    bool activeAssigned = false;

    for (var i = 0; i < userTests.length; i++) {
      final test = userTests[i];
      String status = (test['status'] ?? '').toString().toLowerCase().trim();
      if (!activeAssigned) {
        if (status != 'active') {
          status = 'active';
          changed = true;
        }
        activeAssigned = true;
        test.remove('archived_at');
      } else {
        if (status != 'archived') {
          status = 'archived';
          changed = true;
        }
        if (test['archived_at'] == null) {
          test['archived_at'] =
              test['created_at'] ?? DateTime.now().toIso8601String();
          changed = true;
        }
      }

      if ((test['status'] ?? '') != status) {
        test['status'] = status;
        changed = true;
      }

      if (_updateHemogramStatusInAll(
        allTests,
        (test['id'] as num?)?.toInt(),
        status,
        test['archived_at'],
      )) {
        changed = true;
      }
    }

    return changed;
  }

  bool _updateHemogramStatusInAll(
    List<Map<String, dynamic>> allTests,
    int? id,
    String status,
    dynamic archivedAt,
  ) {
    if (id == null) return false;
    for (final test in allTests) {
      if ((test['id'] as num?)?.toInt() == id) {
        bool mutated = false;
        if (test['status'] != status) {
          test['status'] = status;
          mutated = true;
        }
        if (status == 'archived') {
          if (test['archived_at'] != archivedAt) {
            test['archived_at'] = archivedAt;
            mutated = true;
          }
        } else if (test.containsKey('archived_at')) {
          test.remove('archived_at');
          mutated = true;
        }
        return mutated;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> getActiveHemogramTest(int userId) async {
    final userTests = await getHemogramTests(userId);
    return userTests.isNotEmpty ? userTests.first : null;
  }

  // Medication management
  Future<int> addMedication(int userId, String name, String dosage,
      String frequency, String time) async {
    try {
      if (_prefs == null) await init();
      List<Map<String, dynamic>> medications = await getMedications(userId);
      final int newId = DateTime.now().millisecondsSinceEpoch;

      Map<String, dynamic> medication = {
        'id': newId,
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'time_to_take': time,
        // Align with native schema expectations for sync consistency
        'total_days': 1,
        'completed_days': 0,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      medications.add(medication);
      await persistMedications(userId, medications);
      return newId;
    } catch (e) {
      debugPrint('Medication add error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getMedications(int userId) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('medications_$userId');
      if (data != null) {
        List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Medication list load error: $e');
      return [];
    }
  }

  Future<int> updateMedicationStatus(int medicationId, bool isActive) async {
    try {
      if (_prefs == null) await init();
      // Check all users' medications
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith('medications_')) {
          String? data = _prefs!.getString(key);
          if (data != null) {
            List<Map<String, dynamic>> medications =
                (jsonDecode(data) as List).cast<Map<String, dynamic>>();
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
      debugPrint('Medication status update error: $e');
      return 0;
    }
  }

  Future<int> insertMedicationFromMap(Map<String, dynamic> medication) async {
    if (_prefs == null) await init();
    final userId = medication['user_id'] as int? ?? 0;
    final meds = await getMedications(userId);
    final int assignedId =
        medication['id'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final payload = <String, dynamic>{
      'id': assignedId,
      'user_id': userId,
      'name': medication['name'],
      'dosage': medication['dosage'],
      'frequency': medication['frequency'],
      'time_to_take': medication['time_to_take'] ?? medication['time'],
      'total_days': (medication['total_days'] is num)
          ? (medication['total_days'] as num).toInt()
          : 1,
      'completed_days': (medication['completed_days'] is num)
          ? (medication['completed_days'] as num).toInt()
          : 0,
      'is_active':
          (medication['is_active'] == 0 || medication['is_active'] == false)
              ? 0
              : 1,
      'created_at':
          medication['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    meds.removeWhere((m) => m['id'] == assignedId);
    meds.add(payload);
    await persistMedications(userId, meds);
    return assignedId;
  }

  Future<int> updateMedicationFromMap(
      int medicationId, Map<String, dynamic> medication) async {
    if (_prefs == null) await init();
    for (final key in _prefs!.getKeys()) {
      if (!key.startsWith('medications_')) continue;
      final data = _prefs!.getString(key);
      if (data == null) continue;
      final List<dynamic> decoded = jsonDecode(data);
      bool updated = false;
      for (var i = 0; i < decoded.length; i++) {
        final entry = Map<String, dynamic>.from(decoded[i] as Map);
        if (entry['id'] == medicationId) {
          final merged = {
            ...entry,
            ...medication,
          };
          merged['time_to_take'] =
              merged['time_to_take'] ?? merged['time'] ?? entry['time_to_take'];
          merged['is_active'] =
              (merged['is_active'] == 0 || merged['is_active'] == false)
                  ? 0
                  : 1;
          merged['updated_at'] = DateTime.now().toIso8601String();
          decoded[i] = merged;
          updated = true;
          break;
        }
      }
      if (updated) {
        await _prefs!.setString(key, jsonEncode(decoded));
        return 1;
      }
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getMedicationsNormalized(
      int userId) async {
    final meds = await getMedications(userId);
    meds.sort((a, b) {
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });
    return meds
        .where((m) => !(m['is_active'] == 0 || m['is_active'] == false))
        .map((m) => {
              ...m,
              'time_to_take': m['time_to_take'] ?? m['time'],
              'is_active':
                  (m['is_active'] == 0 || m['is_active'] == false) ? 0 : 1,
            })
        .toList();
  }

  Future<void> persistMedications(
      int userId, List<Map<String, dynamic>> medications) async {
    if (_prefs == null) await init();
    await _prefs!.setString('medications_$userId', jsonEncode(medications));
  }

  // Medication intake record (web): store per-day flag for taken/not-taken
  Future<void> updateMedicationTaken(
      int medicationId, int userId, bool taken) async {
    if (_prefs == null) await init();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'med_taken_${medicationId}_$today';
    await _prefs!.setBool(key, taken);
    // Optionally append to a lightweight log list for simple history
    final logKey = 'med_logs_$medicationId';
    final existing = _prefs!.getStringList(logKey) ?? <String>[];
    final entry = jsonEncode({
      'date': today,
      'time': DateTime.now().toIso8601String().split('T').elementAt(1),
      'taken': taken,
      'user_id': userId,
    });
    // Replace any existing today's entry
    existing.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['date'] == today;
      } catch (_) {
        return false;
      }
    });
    existing.add(entry);
    await _prefs!.setStringList(logKey, existing);
  }

  Future<bool> wasMedicationTakenToday(int medicationId) async {
    if (_prefs == null) await init();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'med_taken_${medicationId}_$today';
    return _prefs!.getBool(key) ?? false;
  }

  // Notification management
  Future<int> createNotification(
      int userId, String title, String message, String type) async {
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

      notifications.insert(0, notification); // Insert at the top
      await _prefs!
          .setString('notifications_$userId', jsonEncode(notifications));
      return newId;
    } catch (e) {
      debugPrint('Notification create error: $e');
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
      debugPrint('Notification list load error: $e');
      return [];
    }
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    try {
      // Check all users' notifications
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith('notifications_')) {
          String? data = _prefs!.getString(key);
          if (data != null) {
            List<Map<String, dynamic>> notifications =
                (jsonDecode(data) as List).cast<Map<String, dynamic>>();
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
      debugPrint('Notification mark-read error: $e');
      return 0;
    }
  }

  Future<int> deleteNotification(int notificationId) async {
    try {
      // Check all users' notifications
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith('notifications_')) {
          String? data = _prefs!.getString(key);
          if (data != null) {
            List<Map<String, dynamic>> notifications =
                (jsonDecode(data) as List).cast<Map<String, dynamic>>();
            notifications.removeWhere((n) => n['id'] == notificationId);
            await _prefs!.setString(key, jsonEncode(notifications));
            return 1;
          }
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Notification delete error: $e');
      return 0;
    }
  }

  // Reminders
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
      debugPrint('Reminder create error: $e');
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
      debugPrint('Reminder list load error: $e');
      return [];
    }
  }

  Future<int> updateReminderStatus(
      int userId, int reminderId, bool isActive) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('reminders_$userId');
      if (data == null) return 0;
      List<Map<String, dynamic>> reminders =
          (jsonDecode(data) as List).cast<Map<String, dynamic>>();
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
      debugPrint('Reminder status update error: $e');
      return 0;
    }
  }

  Future<int> deleteReminder(int userId, int reminderId) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('reminders_$userId');
      if (data == null) return 0;
      List<Map<String, dynamic>> reminders =
          (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      int before = reminders.length;
      reminders.removeWhere((r) => r['id'] == reminderId);
      if (reminders.length == before) return 0;
      await _prefs!.setString('reminders_$userId', jsonEncode(reminders));
      return 1;
    } catch (e) {
      debugPrint('Reminder delete error: $e');
      return 0;
    }
  }

  // Water tracking
  Future<int> logWaterIntake(int userId, int glassCount) async {
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      await _prefs!.setInt('water_${userId}_$today', glassCount);
      // Also update daily_activities
      await _updateDailyActivityWeb(userId, today, waterGlasses: glassCount);
      return 1;
    } catch (e) {
      debugPrint('Water log save error: $e');
      return 0;
    }
  }

  // ===== Daily Activities Methods (Web) =====
  Future<void> _updateDailyActivityWeb(
    int userId,
    String date, {
    int? steps,
    int? sleepMinutes,
    int? waterGlasses,
  }) async {
    if (_prefs == null) await init();
    final key = 'daily_activity_${userId}_$date';
    final existing = _prefs!.getString(key);
    final now = DateTime.now().toIso8601String();
    
    Map<String, dynamic> data = existing != null
        ? Map<String, dynamic>.from(jsonDecode(existing))
        : {
            'user_id': userId,
            'date': date,
            'created_at': now,
          };
    
    if (steps != null) data['steps'] = steps;
    if (sleepMinutes != null) data['sleep_minutes'] = sleepMinutes;
    if (waterGlasses != null) data['water_glasses'] = waterGlasses;
    data['updated_at'] = now;
    
    await _prefs!.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getDailyActivity(int userId, String date) async {
    try {
      if (_prefs == null) await init();
      final key = 'daily_activity_${userId}_$date';
      final data = _prefs!.getString(key);
      if (data != null) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
      return null;
    } catch (e) {
      debugPrint('Daily activity load error: $e');
      return null;
    }
  }

  Future<int> logSteps(int userId, int steps, {String? date}) async {
    try {
      if (_prefs == null) await init();
      final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
      await _updateDailyActivityWeb(userId, targetDate, steps: steps);
      return steps;
    } catch (e) {
      debugPrint('Steps log error: $e');
      return 0;
    }
  }

  Future<int> logSleep(int userId, int sleepMinutes, {String? date}) async {
    try {
      if (_prefs == null) await init();
      final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
      await _updateDailyActivityWeb(userId, targetDate, sleepMinutes: sleepMinutes);
      return sleepMinutes;
    } catch (e) {
      debugPrint('Sleep log error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivities(int userId, {DateTime? startDate}) async {
    try {
      if (_prefs == null) await init();
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = DateTime.now();
      final List<Map<String, dynamic>> activities = [];
      
      for (int i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final activity = await getDailyActivity(userId, dateStr);
        if (activity != null) {
          activities.add(activity);
        }
      }
      
      return activities;
    } catch (e) {
      debugPrint('Weekly activities load error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyActivities(int userId, {DateTime? startDate}) async {
    try {
      if (_prefs == null) await init();
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = DateTime.now();
      final List<Map<String, dynamic>> activities = [];
      
      for (int i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final activity = await getDailyActivity(userId, dateStr);
        if (activity != null) {
          activities.add(activity);
        }
      }
      
      return activities;
    } catch (e) {
      debugPrint('Monthly activities load error: $e');
      return [];
    }
  }

  // ===== User Goals Methods (Web) =====
  Future<Map<String, dynamic>> getUserGoals(int userId) async {
    try {
      if (_prefs == null) await init();
      final key = 'user_goals_$userId';
      final data = _prefs!.getString(key);
      if (data != null) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
      // Create default goals
      final defaultGoals = {
        'user_id': userId,
        'steps_goal': 10000,
        'water_goal': 8,
        'sleep_goal': 480,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _prefs!.setString(key, jsonEncode(defaultGoals));
      return defaultGoals;
    } catch (e) {
      debugPrint('User goals load error: $e');
      return {
        'user_id': userId,
        'steps_goal': 10000,
        'water_goal': 8,
        'sleep_goal': 480,
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> updateUserGoals(int userId, {
    int? stepsGoal,
    int? waterGoal,
    int? sleepGoal,
  }) async {
    try {
      if (_prefs == null) await init();
      final key = 'user_goals_$userId';
      final existing = _prefs!.getString(key);
      final now = DateTime.now().toIso8601String();
      
      Map<String, dynamic> data = existing != null
          ? Map<String, dynamic>.from(jsonDecode(existing))
          : {
              'user_id': userId,
              'steps_goal': 10000,
              'water_goal': 8,
              'sleep_goal': 480,
            };
      
      if (stepsGoal != null) data['steps_goal'] = stepsGoal;
      if (waterGoal != null) data['water_goal'] = waterGoal;
      if (sleepGoal != null) data['sleep_goal'] = sleepGoal;
      data['updated_at'] = now;
      
      await _prefs!.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('User goals update error: $e');
    }
  }

  Future<int> getTodayWaterIntake(int userId) async {
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      return _prefs!.getInt('water_${userId}_$today') ?? 0;
    } catch (e) {
      debugPrint('Water log load error: $e');
      return 0;
    }
  }

  Future<List<int>> getLast7DaysWaterIntake(int userId) async {
    try {
      if (_prefs == null) await init();
      final now = DateTime.now();
      final List<int> values = [];
      for (int i = 6; i >= 0; i--) {
        final day =
            now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        final v = _prefs!.getInt('water_${userId}_$day') ?? 0;
        values.add(v);
      }
      return values;
    } catch (e) {
      debugPrint('Water last7 load error: $e');
      return List<int>.filled(7, 0);
    }
  }

  // Diet tracking (web): store per-day booleans for meals
  Future<Map<String, dynamic>?> getDietTrackingForDate(
      int userId, String date) async {
    try {
      if (_prefs == null) await init();
      final key = 'diet_${userId}_$date';
      final str = _prefs!.getString(key);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Diet get error: $e');
      return null;
    }
  }

  Future<int> upsertDietTracking({
    required int userId,
    required String date,
    required bool breakfast,
    required bool lunch,
    required bool dinner,
    required bool snack,
    String? notes,
  }) async {
    try {
      if (_prefs == null) await init();
      final key = 'diet_${userId}_$date';
      final payload = {
        'user_id': userId,
        'date': date,
        'breakfast': breakfast ? 1 : 0,
        'lunch': lunch ? 1 : 0,
        'dinner': dinner ? 1 : 0,
        'snack': snack ? 1 : 0,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _prefs!.setString(key, jsonEncode(payload));
      return 1;
    } catch (e) {
      debugPrint('Diet upsert error: $e');
      return 0;
    }
  }

  // Advanced analytics helpers
  Future<List<Map<String, dynamic>>> getHemogramTestsByUser(int userId) async {
    return await getHemogramTests(userId);
  }

  // Clear the database
  Future<void> clearDatabase() async {
    if (_prefs == null) await init();

    await _prefs!.remove('users');
    await _prefs!.remove('hemogram_tests');
    await _prefs!.remove('family_members');
    await _prefs!.remove('family_invitations');
  }

  // Emergency contacts (web)
  Future<List<Map<String, dynamic>>> getEmergencyContacts([int? userId]) async {
    try {
      if (_prefs == null) await init();
      String? data = _prefs!.getString('emergency_contacts_${userId ?? 0}');
      if (data != null) {
        List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Emergency contacts load error: $e');
      return [];
    }
  }

  Future<int> addEmergencyContact({
    required int userId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    try {
      if (_prefs == null) await init();
      List<Map<String, dynamic>> contacts = await getEmergencyContacts(userId);
      int newId = contacts.length + 1;

      Map<String, dynamic> contact = {
        'id': newId,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'relation': relation,
        'created_at': DateTime.now().toIso8601String(),
      };

      contacts.add(contact);
      await _prefs!
          .setString('emergency_contacts_$userId', jsonEncode(contacts));
      return newId;
    } catch (e) {
      debugPrint('Emergency contact add error: $e');
      return 0;
    }
  }

  Future<int> deleteEmergencyContact(int id) async {
    try {
      if (_prefs == null) await init();
      // Find which user this belongs to by searching all users
      final allContacts = await getEmergencyContacts();
      for (var contact in allContacts) {
        if (contact['id'] == id) {
          final userId = contact['user_id'];
          final contacts = await getEmergencyContacts(userId);
          contacts.removeWhere((c) => c['id'] == id);
          await _prefs!
              .setString('emergency_contacts_$userId', jsonEncode(contacts));
          return 1;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Emergency contact delete error: $e');
      return 0;
    }
  }

  // Reminder streaks & logs (web)
  Future<Map<String, dynamic>> getReminderStreak(int reminderId,
      {int? userId}) async {
    if (_prefs == null) await init();
    final key = 'streak_${userId ?? 0}_$reminderId';
    final str = _prefs!.getString(key);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return {
      'reminder_id': reminderId,
      'user_id': userId,
      'current_streak': 0,
      'longest_streak': 0,
      'last_completed_date': null,
    };
  }

  Future<int> upsertReminderStreak({
    required int reminderId,
    int? userId,
    required int currentStreak,
    required int longestStreak,
    String? lastCompletedDate,
  }) async {
    if (_prefs == null) await init();
    final key = 'streak_${userId ?? 0}_$reminderId';
    final payload = {
      'reminder_id': reminderId,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completed_date': lastCompletedDate,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _prefs!.setString(key, jsonEncode(payload));
    return 1;
  }

  Future<int> insertReminderLog({
    required int reminderId,
    int? userId,
    required String action,
    required DateTime actionDate,
    DateTime? scheduledTime,
    String? metadata,
  }) async {
    if (_prefs == null) await init();
    final key = 'logs_${userId ?? 0}_$reminderId';
    final existing = _prefs!.getStringList(key) ?? <String>[];
    final row = {
      'reminder_id': reminderId,
      'user_id': userId,
      'action': action,
      'action_date': actionDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime?.toIso8601String(),
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    };
    existing.add(jsonEncode(row));
    await _prefs!.setStringList(key, existing);
    return 1;
  }
}
