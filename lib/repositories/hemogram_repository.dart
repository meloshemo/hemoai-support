import 'package:flutter/foundation.dart';

import '../services/database_helper.dart';
import '../services/web_database_helper.dart';

/// Repository for Hemogram test data. Provides a unified API across web and native.
class HemogramRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final WebDatabaseHelper _web = WebDatabaseHelper.instance;

  Future<int> insertHemogramTest(Map<String, dynamic> test) async {
    if (kIsWeb) {
      return await _web.insertHemogramTest(test);
    }
    return await _db.insertHemogramTest(test);
  }

  Future<List<Map<String, dynamic>>> getHemogramTests(int userId) async {
    if (kIsWeb) {
      return await _web.getHemogramTests(userId);
    }
    return await _db.getHemogramTests(userId);
  }

  Future<Map<String, dynamic>?> getLatestHemogramTest(int userId) async {
    if (kIsWeb) {
      return await _web.getLatestHemogramTest(userId);
    }
    return await _db.getLatestHemogramTest(userId);
  }
}
