import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/database_helper.dart';
import '../services/web_database_helper.dart';

class HemogramRecord {
  HemogramRecord({
    required this.id,
    required this.userId,
    required this.testDate,
    required this.values,
    required this.raw,
    required this.status,
    this.archivedAt,
  });

  final int id;
  final int userId;
  final DateTime testDate;
  final Map<String, double> values;
  final Map<String, dynamic> raw;
  final String status;
  final DateTime? archivedAt;

  bool get isActive => status == 'active';
}

/// Repository for Hemogram test data. Provides a unified API across web and native.
class HemogramRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final WebDatabaseHelper _web = WebDatabaseHelper.instance;

  static const _numericColumns = {
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
    'glucose',
    'alt',
    'ast',
    'crp',
    'tsh',
    'vitamin_d3',
    'vitamin_b12',
    'calcium',
    'sodium',
    'potassium',
    'ggt',
    'bilirubin',
    'creatinine',
    'urea',
  };

  Future<int> saveHemogram({
    required int userId,
    required Map<String, double> values,
    DateTime? testDate,
  }) async {
    if (values.isEmpty) {
      return 0;
    }
    final payload = <String, dynamic>{
      'user_id': userId,
      'test_date': (testDate ?? DateTime.now()).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'values_json': jsonEncode(values),
      'status': 'active',
    };

    for (final entry in values.entries) {
      if (_numericColumns.contains(entry.key)) {
        payload[entry.key] = entry.value;
      }
    }

    if (kIsWeb) {
      return await _web.insertHemogramTest(payload);
    }
    return await _db.insertHemogramTest(payload);
  }

  Future<HemogramRecord?> getActiveHemogram(int userId) async {
    final row = await _getActiveHemogramRow(userId);
    if (row == null) return null;
    return _mapRowToRecord(row);
  }

  Future<List<HemogramRecord>> getHemogramHistory(int userId) async {
    final rows = await _getHemogramRows(userId);
    return rows.map(_mapRowToRecord).toList();
  }

  @Deprecated('Use saveHemogram instead')
  Future<int> insertHemogramTest(Map<String, dynamic> test) async {
    if (kIsWeb) {
      return await _web.insertHemogramTest(test);
    }
    return await _db.insertHemogramTest(test);
  }

  @Deprecated('Use getHemogramHistory instead')
  Future<List<Map<String, dynamic>>> getHemogramTests(int userId) async {
    return await _getHemogramRows(userId);
  }

  @Deprecated('Use getActiveHemogram instead')
  Future<Map<String, dynamic>?> getLatestHemogramTest(int userId) async {
    return await _getActiveHemogramRow(userId);
  }

  Future<List<Map<String, dynamic>>> _getHemogramRows(int userId) async {
    if (kIsWeb) {
      return await _web.getHemogramTests(userId);
    }
    return await _db.getHemogramTests(userId);
  }

  Future<Map<String, dynamic>?> _getActiveHemogramRow(int userId) async {
    if (kIsWeb) {
      return await _web.getActiveHemogramTest(userId);
    }
    return await _db.getActiveHemogramTest(userId);
  }

  HemogramRecord _mapRowToRecord(Map<String, dynamic> row) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final userId = (row['user_id'] as num?)?.toInt() ?? 0;
    final testDateStr = (row['test_date'] ?? row['created_at'] ?? '') as String;
    final testDate = DateTime.tryParse(testDateStr) ?? DateTime.now();
    final status =
        (row['status'] ?? 'active').toString().toLowerCase() == 'archived'
            ? 'archived'
            : 'active';
    final archivedAtStr = row['archived_at'] as String?;
    final archivedAt =
        archivedAtStr != null ? DateTime.tryParse(archivedAtStr) : null;

    Map<String, double> values = {};
    final valuesJson = row['values_json'];
    if (valuesJson is String && valuesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(valuesJson) as Map<String, dynamic>;
        values = {};
        decoded.forEach((key, value) {
          double? parsed;
          if (value is num) {
            parsed = value.toDouble();
          } else if (value is String) {
            parsed = double.tryParse(value);
          }
          if (parsed != null) {
            values[key] = parsed;
          }
        });
      } catch (_) {
        values = {};
      }
    }

    for (final key in _numericColumns) {
      final v = row[key];
      if (v != null) {
        if (v is num) {
          values[key] = v.toDouble();
        } else if (v is String) {
          final parsed = double.tryParse(v);
          if (parsed != null) {
            values[key] = parsed;
          }
        }
      }
    }

    return HemogramRecord(
      id: id,
      userId: userId,
      testDate: testDate,
      values: values,
      raw: row,
      status: status,
      archivedAt: archivedAt,
    );
  }
}
