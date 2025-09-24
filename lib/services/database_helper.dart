import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
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
    // Kullanıcılar tablosu
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

    // Aile üyeleri tablosu
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

    // Aile üyeleri hemogram testleri
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

    // İlaçlar tablosu
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

    // İlaç alım kayıtları
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

  // Kullanıcı işlemleri
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

  // Hemogram test işlemleri
  Future<int> insertHemogramTest(Map<String, dynamic> test) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseHelper).insertHemogramTest(test);
    } else {
      test['created_at'] = DateTime.now().toIso8601String();
      return await (db as Database).insert('hemogram_tests', test);
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

  // Aile üyesi işlemleri
  Future<int> insertFamilyMember(Map<String, dynamic> member) async {
    final db = await database;
    member['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('family_members', member);
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(int userId) async {
    final db = await database;
    return await db.query(
      'family_members',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
  }

  Future<int> updateFamilyMember(int id, Map<String, dynamic> member) async {
    final db = await database;
    return await db.update(
      'family_members',
      member,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await database;
    return await db.delete(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Aile üyesi hemogram testleri
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

  // İlaç işlemleri
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

  // İlaç alım kaydı
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

  // Bildirim işlemleri
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
    
    // Toplam test sayısı
    final testCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM hemogram_tests WHERE user_id = ?',
      [userId],
    );
    
    // Aile üyesi sayısı
    final familyCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM family_members WHERE user_id = ?',
      [userId],
    );
    
    // Aktif ilaç sayısı
    final medicationCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM medications WHERE user_id = ? AND is_active = 1',
      [userId],
    );
    
    // Okunmamış bildirim sayısı
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

  // Veritabanını temizle
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

  // Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

// Hemogram değerleri için yardımcı sınıf
class HemogramValues {
  static Map<String, String> getColumnNames() {
    return {
      'Hemoglobin (g/dL)': 'hemoglobin',
      'Demir (mcg/dL)': 'iron',
      'Lökosit (K/uL)': 'leukocyte',
      'Eritrosit (M/uL)': 'erythrocyte',
      'Hematokrit (%)': 'hematocrit',
      'Trombosit (K/uL)': 'platelet',
      'MCV (fL)': 'mcv',
      'MCH (pg)': 'mch',
      'MCHC (g/dL)': 'mchc',
      'RDW (%)': 'rdw',
      'Nötrofil (%)': 'neutrophil',
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
      if (columnName != null) {
        dbValues[columnName] = value;
      }
    });
    
    return dbValues;
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