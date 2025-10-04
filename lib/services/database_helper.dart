import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'web_database_helper.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  static WebDatabaseHelper? _webHelper;

  DatabaseHelper._internal();
  
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<dynamic> get database async {
    if (kIsWeb) {
      _webHelper ??= WebDatabaseHelper.instance;
      await _webHelper!.init();
      return _webHelper;
    } else {
      _database ??= await _initDatabase();
      return _database!;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hemoai.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
  // Kullanicilar tablosu
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        bmi REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

  // Hemogram testleri tablosu
    await db.execute('''
      CREATE TABLE hemogram_tests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        test_date TEXT NOT NULL,
        hemoglobin REAL,
        iron REAL,
        leukocyte REAL,
        erythrocyte REAL,
        hematocrit REAL,
        platelet REAL,
        mcv REAL,
        mch REAL,
        mchc REAL,
        rdw REAL,
        neutrophil REAL,
        lymphocyte REAL,
        monocyte REAL,
        eosinophil REAL,
        basophil REAL,
        risk_level TEXT,
        doctor_notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

  // Aile uyeleri tablosu
    await db.execute('''
      CREATE TABLE family_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        avatar TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

  // Aile uyeleri hemogram testleri
    await db.execute('''
      CREATE TABLE family_hemogram_tests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        family_member_id INTEGER NOT NULL,
        test_date TEXT NOT NULL,
        hemoglobin REAL,
        iron REAL,
        leukocyte REAL,
        erythrocyte REAL,
        hematocrit REAL,
        platelet REAL,
        mcv REAL,
        mch REAL,
        mchc REAL,
        rdw REAL,
        neutrophil REAL,
        lymphocyte REAL,
        monocyte REAL,
        eosinophil REAL,
        basophil REAL,
        risk_level TEXT,
        doctor_notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (family_member_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

  // Ilaclar tablosu
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        time_to_take TEXT NOT NULL,
        total_days INTEGER NOT NULL,
        completed_days INTEGER DEFAULT 0,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

  // Ilac alim kayitlari
    await db.execute('''
      CREATE TABLE medication_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        taken_date TEXT NOT NULL,
        taken_time TEXT NOT NULL,
        was_taken INTEGER NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

  // Bildirimler tablosu
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        icon_data TEXT,
        color_value INTEGER,
        is_read INTEGER DEFAULT 0,
        scheduled_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

  // Hatirlaticilar tablosu
    await db.execute('''
      CREATE TABLE reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        scheduled_time INTEGER NOT NULL,
        type INTEGER NOT NULL,
        repeat_type INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

  // Su takibi
    await db.execute('''
      CREATE TABLE water_tracking(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        water_count INTEGER NOT NULL,
        goal INTEGER DEFAULT 8,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Kullanici islemleri
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).insertUser(user);
    } else {
      user['created_at'] = DateTime.now().toIso8601String();
      user['updated_at'] = DateTime.now().toIso8601String();
      return await (db as Database).insert('users', user);
    }
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).getUser(email);
    } else {
      final List<Map<String, dynamic>> users = await (db as Database).query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return users.isNotEmpty ? users.first : null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).getUserById(id);
    } else {
      final List<Map<String, dynamic>> users = await (db as Database).query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      return users.isNotEmpty ? users.first : null;
    }
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).updateUser(id, user);
    } else {
      user['updated_at'] = DateTime.now().toIso8601String();
      return await (db as Database).update(
        'users',
        user,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Hemogram test islemleri
  Future<int> insertHemogramTest(Map<String, dynamic> test) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).insertHemogramTest(test);
    } else {
      // Sanitize map to only include columns that exist in hemogram_tests
      final allowedColumns = <String>{
        'user_id',
        'test_date',
        'hemoglobin',
        'iron',
        'leukocyte',
        'erythrocyte',
        'hematocrit',
        'platelet',
        'mcv',
        'mch',
        'mchc',
        'rdw',
        'neutrophil',
        'lymphocyte',
        'monocyte',
        'eosinophil',
        'basophil',
        'risk_level',
        'doctor_notes',
        'created_at',
      };

      // Map extended/canonical keys to existing DB columns when possible
      Map<String, dynamic> sanitized = {};
      // Direct allowed keys
      for (final entry in test.entries) {
        if (allowedColumns.contains(entry.key)) {
          sanitized[entry.key] = entry.value;
        }
      }
      // Try to map canonical keys from extended model
      void tryAssign(String canonicalKey, String dbColumn) {
        if (!sanitized.containsKey(dbColumn) && test.containsKey(canonicalKey)) {
          sanitized[dbColumn] = test[canonicalKey];
        }
      }
      tryAssign('white_blood_cells', 'leukocyte');
      tryAssign('red_blood_cells', 'erythrocyte');
      tryAssign('platelets', 'platelet');
      tryAssign('neutrophils', 'neutrophil');
      tryAssign('lymphocytes', 'lymphocyte');
      tryAssign('monocytes', 'monocyte');
      tryAssign('eosinophils', 'eosinophil');
      tryAssign('basophils', 'basophil');

      // Ensure mandatory metadata
      sanitized['created_at'] = DateTime.now().toIso8601String();

      return await (db as Database).insert('hemogram_tests', sanitized);
    }
  }

  Future<List<Map<String, dynamic>>> getHemogramTests(int userId) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).getHemogramTests(userId);
    } else {
      return await (db as Database).query(
        'hemogram_tests',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'test_date DESC',
      );
    }
  }

  Future<Map<String, dynamic>?> getLatestHemogramTest(int userId) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).getLatestHemogramTest(userId);
    } else {
      final List<Map<String, dynamic>> tests = await (db as Database).query(
        'hemogram_tests',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'test_date DESC',
        limit: 1,
      );
      return tests.isNotEmpty ? tests.first : null;
    }
  }

  // Aile uyesi islemleri
  Future<int> insertFamilyMember(Map<String, dynamic> member) async {
    if (kIsWeb) {
      return await _webHelper!.insertFamilyMember(member);
    } else {
      final db = await database;
      member['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('family_members', member);
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(int userId) async {
    if (kIsWeb) {
      return await _webHelper!.getFamilyMembers(userId);
    } else {
      final db = await database;
      return await db.query(
        'family_members',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
    }
  }

  Future<int> updateFamilyMember(int id, Map<String, dynamic> member) async {
    if (kIsWeb) {
      return await _webHelper!.updateFamilyMember(id, member);
    } else {
      final db = await database;
      return await db.update(
        'family_members',
        member,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> deleteFamilyMember(int id) async {
    if (kIsWeb) {
      return await _webHelper!.deleteFamilyMember(id);
    } else {
      final db = await database;
      return await db.delete(
        'family_members',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Aile uyesi hemogram testleri
  Future<int> insertFamilyHemogramTest(Map<String, dynamic> test) async {
    final db = await database;
    test['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('family_hemogram_tests', test);
  }

  Future<List<Map<String, dynamic>>> getFamilyHemogramTests(int familyMemberId) async {
    final db = await database;
    return await db.query(
      'family_hemogram_tests',
      where: 'family_member_id = ?',
      whereArgs: [familyMemberId],
      orderBy: 'test_date DESC',
    );
  }

  // Ilac islemleri
  Future<int> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;
    medication['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('medications', medication);
  }

  Future<List<Map<String, dynamic>>> getMedications(int userId) async {
    final db = await database;
    return await db.query(
      'medications',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
  }

  Future<int> updateMedication(int id, Map<String, dynamic> medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ilac alim kaydi
  Future<int> insertMedicationLog(Map<String, dynamic> log) async {
    final db = await database;
    log['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('medication_logs', log);
  }

  Future<bool> wasMedicationTakenToday(int medicationId) async {
    final db = await database;
    String today = DateTime.now().toIso8601String().substring(0, 10);
    
    final List<Map<String, dynamic>> logs = await db.query(
      'medication_logs',
      where: 'medication_id = ? AND taken_date = ? AND was_taken = 1',
      whereArgs: [medicationId, today],
    );
    
    return logs.isNotEmpty;
  }

  // Bildirim islemleri
  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    notification['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('notifications', notification);
  }

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scheduled_date DESC, created_at DESC',
    );
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    if (kIsWeb) {
      return await _webHelper!.deleteNotification(id);
    } else {
      return await (db as Database).delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Su takibi
  Future<int> insertWaterTracking(Map<String, dynamic> tracking) async {
    final db = await database;
    tracking['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('water_tracking', tracking);
  }

  Future<Map<String, dynamic>?> getTodayWaterTracking(int userId) async {
    final db = await database;
    String today = DateTime.now().toIso8601String().substring(0, 10);
    
    final List<Map<String, dynamic>> tracking = await db.query(
      'water_tracking',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );
    
    return tracking.isNotEmpty ? tracking.first : null;
  }

  Future<int> updateWaterTracking(int userId, int waterCount) async {
    final db = await database;
    String today = DateTime.now().toIso8601String().substring(0, 10);
    
    Map<String, dynamic>? existing = await getTodayWaterTracking(userId);
    
    if (existing != null) {
      return await db.update(
        'water_tracking',
        {'water_count': waterCount},
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, today],
      );
    } else {
      return await insertWaterTracking({
        'user_id': userId,
        'date': today,
        'water_count': waterCount,
        'goal': 8,
      });
    }
  }

  // Genel istatistikler
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await database;
    
  // Toplam test sayisi
    final testCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM hemogram_tests WHERE user_id = ?',
      [userId],
    );
    
  // Aile uyesi sayisi
    final familyCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM family_members WHERE user_id = ?',
      [userId],
    );
    
  // Aktif ilac sayisi
    final medicationCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM medications WHERE user_id = ? AND is_active = 1',
      [userId],
    );
    
  // Okunmamis bildirim sayisi
    final notificationCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    
    return {
      'total_tests': testCount.first['count'] ?? 0,
      'family_members': familyCount.first['count'] ?? 0,
      'active_medications': medicationCount.first['count'] ?? 0,
      'unread_notifications': notificationCount.first['count'] ?? 0,
    };
  }

  // Veritabanini temizle
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('hemogram_tests');
    await db.delete('family_members');
    await db.delete('family_hemogram_tests');
    await db.delete('medications');
    await db.delete('medication_logs');
    await db.delete('notifications');
    await db.delete('water_tracking');
  }

  // Veritabanini kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Davet sistemi
  Future<int> sendFamilyInvitation(Map<String, dynamic> invitation) async {
    if (kIsWeb) {
      return await _webHelper!.sendFamilyInvitation(invitation);
    } else {
      final db = await database;
      invitation['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('family_invitations', invitation);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(int userId) async {
    if (kIsWeb) {
      return await _webHelper!.getPendingInvitations(userId);
    } else {
      final db = await database;
      return await db.query(
        'family_invitations',
        where: 'to_user_id = ? AND status = ?',
        whereArgs: [userId, 'pending'],
      );
    }
  }

  Future<int> respondToInvitation(int invitationId, String response) async {
    if (kIsWeb) {
      return await _webHelper!.respondToInvitation(invitationId, response);
    } else {
      final db = await database;
      return await db.update(
        'family_invitations',
        {
          'status': response,
          'responded_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invitationId],
      );
    }
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    if (kIsWeb) {
      return await _webHelper!.findUserByPhone(phone);
    } else {
      final db = await database;
      List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    }
  }

  // Ilac yonetimi
  Future<int> addMedication(int userId, String name, String dosage, String frequency, String time) async {
    if (kIsWeb) {
      return await _webHelper!.addMedication(userId, name, dosage, frequency, time);
    } else {
      final db = await database;
      return await db.insert('medications', {
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'time': time,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Su tuketimi takibi
  Future<int> getTodayWaterIntake(int userId) async {
    if (kIsWeb) {
      return await _webHelper!.getTodayWaterIntake(userId);
    } else {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final results = await db.query(
        'water_tracking',
        columns: ['water_count'],
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, today],
      );

      return results.isNotEmpty && results.first['water_count'] != null
          ? (results.first['water_count'] as num).toInt()
          : 0;
    }
  }

  Future<int> logWaterIntake(int userId, int amount) async {
    if (kIsWeb) {
      return await _webHelper!.logWaterIntake(userId, amount);
    } else {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if there's already a record for today
      final existing = await db.query(
        'water_tracking',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, today],
      );
      
      if (existing.isNotEmpty) {
        // Update existing record
        return await db.update(
          'water_tracking',
          {
            'water_count': amount,
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ? AND date = ?',
          whereArgs: [userId, today],
        );
      } else {
        // Insert new record
        return await db.insert('water_tracking', {
          'user_id': userId,
          'date': today,
          'water_count': amount,
          'goal': 8,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<List<int>> getLast7DaysWaterIntake(int userId) async {
    if (kIsWeb) {
      return await _webHelper!.getLast7DaysWaterIntake(userId);
    } else {
      final db = await database;
      final now = DateTime.now();
      final List<int> values = [];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        final results = await db.query(
          'water_tracking',
          columns: ['water_count'],
          where: 'user_id = ? AND date = ?',
          whereArgs: [userId, day],
        );
        final v = results.isNotEmpty && results.first['water_count'] != null
            ? (results.first['water_count'] as num).toInt()
            : 0;
        values.add(v);
      }
      return values;
    }
  }

  // Bildirim yonetimi
  Future<int> createNotification(int userId, String title, String message, String type) async {
    if (kIsWeb) {
      return await _webHelper!.createNotification(userId, title, message, type);
    } else {
      final db = await database;
      return await db.insert('notifications', {
        'user_id': userId,
        'title': title,
        'subtitle': '',
        'description': message,
        'type': type,
        'priority': 'medium',
        'icon_data': 'Icons.notifications',
        'color_value': 0xFFE53E3E,
        'is_read': 0,
        'scheduled_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Hatirlatici yonetimi
  Future<int> createReminder(Map<String, dynamic> reminderData) async {
    if (kIsWeb) {
  // Web icin local storage kullan
      return DateTime.now().millisecondsSinceEpoch; // Fake ID
    } else {
      final db = await database;
      return await db.insert('reminders', reminderData);
    }
  }

  Future<List<Map<String, dynamic>>> getAllReminders([int? userId]) async {
    if (kIsWeb) {
  // Web icin bos liste dondur (simdilik)
      return [];
    } else {
      final db = await database;
      if (userId != null) {
        return await db.query(
          'reminders',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'scheduled_time ASC',
        );
      } else {
        return await db.query('reminders', orderBy: 'scheduled_time ASC');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getActiveReminders([int? userId]) async {
    if (kIsWeb) {
      return [];
    } else {
      final db = await database;
      String whereClause = 'is_active = 1';
      List<dynamic> whereArgs = [];
      
      if (userId != null) {
        whereClause += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      return await db.query(
        'reminders',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'scheduled_time ASC',
      );
    }
  }

  Future<int> updateReminder(int id, Map<String, dynamic> reminderData) async {
    if (kIsWeb) {
      return 1;
    } else {
      final db = await database;
      return await db.update(
        'reminders',
        reminderData,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> deleteReminder(int id) async {
    if (kIsWeb) {
      return 1;
    } else {
      final db = await database;
      return await db.delete(
        'reminders',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> toggleReminderStatus(int id) async {
    if (kIsWeb) {
      return 1;
    } else {
      final db = await database;
      final reminder = await db.query(
        'reminders',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (reminder.isNotEmpty) {
        final isActive = reminder.first['is_active'] as int;
        return await db.update(
          'reminders',
          {'is_active': isActive == 1 ? 0 : 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      return 0;
    }
  }

  // Advanced Analytics metodlari
  Future<List<Map<String, dynamic>>> getHemogramTestsByUser(int userId) async {
    if (kIsWeb) {
      final webDb = await database;
      return await webDb.getHemogramTestsByUser(userId);
    } else {
      final db = await database;
      return await db.query(
        'hemogram_tests',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'test_date DESC',
      );
    }
  }
}

// Hemogram degerleri icin yardimci sinif
class HemogramValues {
  static Map<String, String> getColumnNames() {
    return {
      'Hemoglobin (g/dL)': 'hemoglobin',
      'Demir (mcg/dL)': 'iron',
      'Lokosit (K/uL)': 'leukocyte',
      'Eritrosit (M/uL)': 'erythrocyte',
      'Hematokrit (%)': 'hematocrit',
      'Trombosit (K/uL)': 'platelet',
      'MCV (fL)': 'mcv',
      'MCH (pg)': 'mch',
      'MCHC (g/dL)': 'mchc',
      'RDW (%)': 'rdw',
      'Notrofil (%)': 'neutrophil',
      'Lenfosit (%)': 'lymphocyte',
      'Monosit (%)': 'monocyte',
      'Eozinofil (%)': 'eosinophil',
      'Bazofil (%)': 'basophil',
    };
  }

  static Map<String, double> mapToDatabase(Map<String, double> userValues) {
    Map<String, String> columnNames = getColumnNames();
    Map<String, double> dbValues = {};
    
    userValues.forEach((key, value) {
      String? columnName = columnNames[key];
      // If not found in legacy display-label mapping, try canonical keys
      columnName ??= _mapCanonicalKeyToDbColumn(key);
      if (columnName != null) {
        dbValues[columnName] = value;
      }
    });
    
    return dbValues;
  }

  // Support mapping from canonical parameter keys used in new UI to DB column names
  static String? _mapCanonicalKeyToDbColumn(String key) {
    switch (key) {
      case 'hemoglobin':
        return 'hemoglobin';
      case 'iron':
        return 'iron';
      case 'white_blood_cells':
        return 'leukocyte';
      case 'red_blood_cells':
        return 'erythrocyte';
      case 'hematocrit':
        return 'hematocrit';
      case 'platelets':
        return 'platelet';
      case 'mcv':
        return 'mcv';
      case 'mch':
        return 'mch';
      case 'mchc':
        return 'mchc';
      case 'rdw':
        return 'rdw';
      case 'neutrophil':
        return 'neutrophil';
      case 'lymphocyte':
        return 'lymphocyte';
      case 'monocyte':
        return 'monocyte';
      case 'eosinophil':
        return 'eosinophil';
      case 'basophil':
        return 'basophil';
      default:
        return null;
    }
  }

  static Map<String, double> mapFromDatabase(Map<String, dynamic> dbValues) {
    Map<String, String> columnNames = getColumnNames();
    Map<String, double> userValues = {};
    
    columnNames.forEach((userKey, dbKey) {
      dynamic value = dbValues[dbKey];
      if (value != null) {
        userValues[userKey] = (value as num).toDouble();
      }
    });
    
    return userValues;
  }

}