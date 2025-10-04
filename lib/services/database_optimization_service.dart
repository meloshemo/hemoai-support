import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Database optimization service for improved query performance.
/// Implements indexing, query optimization, and batch operations.
class DatabaseOptimizationService {
  static final DatabaseOptimizationService _instance = DatabaseOptimizationService._internal();
  factory DatabaseOptimizationService() => _instance;
  DatabaseOptimizationService._internal();

  /// Create performance indexes for frequently queried columns
  Future<void> createPerformanceIndexes(Database db) async {
    try {
      // Hemogram tests indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hemogram_user_date ON hemogram_tests(user_id, test_date DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hemogram_risk_level ON hemogram_tests(risk_level)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hemogram_created_at ON hemogram_tests(created_at DESC)');
      
      // Family members indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_family_user_id ON family_members(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_family_connected_user ON family_members(connected_user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_family_status ON family_members(status)');
      
      // Reminders indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_user_date ON reminders(user_id, reminder_date, reminder_time)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_type ON reminders(type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_repeat ON reminders(repeat_interval)');
      
      // Notifications indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_user_date ON notifications(user_id, created_at DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read, created_at DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)');
      
      // Users index
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)');
      
      debugPrint('Database performance indexes created successfully');
    } catch (e) {
      debugPrint('Error creating database indexes: $e');
    }
  }

  /// Get optimized hemogram history with pagination
  Future<List<Map<String, dynamic>>> getHemogramHistoryOptimized(
    Database db,
    int userId, {
    int offset = 0,
    int limit = 50,
    String? orderBy,
  }) async {
    final order = orderBy ?? 'test_date DESC, created_at DESC';
    
    return await db.query(
      'hemogram_tests',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: order,
      limit: limit,
      offset: offset,
    );
  }

  /// Get family members with connected user data in single query
  Future<List<Map<String, dynamic>>> getFamilyMembersOptimized(
    Database db,
    int userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    return await db.rawQuery('''
      SELECT 
        fm.*,
        cu.name as connected_user_name,
        cu.email as connected_user_email
      FROM family_members fm
      LEFT JOIN users cu ON fm.connected_user_id = cu.id
      WHERE fm.user_id = ?
      ORDER BY fm.created_at DESC
      LIMIT ? OFFSET ?
    ''', [userId, limit, offset]);
  }

  /// Get recent notifications with optimized query
  Future<List<Map<String, dynamic>>> getNotificationsOptimized(
    Database db,
    int userId, {
    int offset = 0,
    int limit = 50,
    bool? isRead,
  }) async {
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (isRead != null) {
      whereClause += ' AND is_read = ?';
      whereArgs.add(isRead ? 1 : 0);
    }

    return await db.query(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Batch insert operations for better performance
  Future<void> batchInsertHemogramTests(
    Database db,
    List<Map<String, dynamic>> tests,
  ) async {
    final batch = db.batch();
    
    for (final test in tests) {
      batch.insert('hemogram_tests', test);
    }
    
    await batch.commit(noResult: true);
  }

  /// Batch update operations
  Future<void> batchUpdateNotifications(
    Database db,
    List<int> notificationIds,
    Map<String, dynamic> updates,
  ) async {
    final batch = db.batch();
    
    for (final id in notificationIds) {
      batch.update(
        'notifications',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Get database statistics for monitoring
  Future<Map<String, dynamic>> getDatabaseStats(Database db) async {
    final stats = <String, dynamic>{};
    
    try {
      // Table counts
      final tables = ['users', 'hemogram_tests', 'family_members', 'reminders', 'notifications'];
      
      for (final table in tables) {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        stats['${table}_count'] = result.first['count'];
      }
      
      // Database size (SQLite specific)
      final sizeResult = await db.rawQuery('PRAGMA page_count');
      final pageSizeResult = await db.rawQuery('PRAGMA page_size');
      
      if (sizeResult.isNotEmpty && pageSizeResult.isNotEmpty) {
        final pageCount = sizeResult.first['page_count'] as int;
        final pageSize = pageSizeResult.first['page_size'] as int;
        stats['database_size_bytes'] = pageCount * pageSize;
        stats['database_size_mb'] = (pageCount * pageSize) / (1024 * 1024);
      }
      
      // Index usage statistics
      final indexStats = await db.rawQuery('''
        SELECT name, sql FROM sqlite_master 
        WHERE type = 'index' AND name LIKE 'idx_%'
      ''');
      stats['custom_indexes_count'] = indexStats.length;
      
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      stats['error'] = e.toString();
    }
    
    return stats;
  }

  /// Clean up old data to maintain performance
  Future<void> cleanupOldData(Database db) async {
    try {
      // Delete notifications older than 6 months
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      await db.delete(
        'notifications',
        where: 'created_at < ? AND is_read = 1',
        whereArgs: [sixMonthsAgo.millisecondsSinceEpoch],
      );
      
      // Clean up old debug logs (if any)
      // This would be implemented based on specific debug log table structure
      
      debugPrint('Database cleanup completed');
    } catch (e) {
      debugPrint('Error during database cleanup: $e');
    }
  }

  /// Vacuum database to reclaim space and optimize performance
  Future<void> vacuumDatabase(Database db) async {
    try {
      await db.execute('VACUUM');
      debugPrint('Database vacuumed successfully');
    } catch (e) {
      debugPrint('Error vacuuming database: $e');
    }
  }

  /// Analyze database statistics for query optimization
  Future<void> analyzeDatabase(Database db) async {
    try {
      await db.execute('ANALYZE');
      debugPrint('Database analyzed successfully');
    } catch (e) {
      debugPrint('Error analyzing database: $e');
    }
  }

  /// Check query performance
  Future<Map<String, dynamic>> explainQuery(Database db, String query, [List<dynamic>? args]) async {
    try {
      final result = await db.rawQuery('EXPLAIN QUERY PLAN $query', args);
      return {
        'query': query,
        'plan': result,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'query': query,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}