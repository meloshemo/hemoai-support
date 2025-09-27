import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<void> logAction(String action, {Map<String, dynamic>? data}) async {
    try {
      final prefs = await _prefs;
      final list = prefs.getStringList('audit_logs') ?? <String>[];
      final entry = {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data ?? {},
      };
      list.add(jsonEncode(entry));
      await prefs.setStringList('audit_logs', list);
    } catch (_) {
      // swallow errors; audit is best-effort
    }
  }

  Future<List<Map<String, dynamic>>> getLogs({int? limit}) async {
    final prefs = await _prefs;
    final list = prefs.getStringList('audit_logs') ?? <String>[];
    final items = list.map((e) {
      try { return jsonDecode(e) as Map<String, dynamic>; } catch (_) { return <String, dynamic>{}; }
    }).where((e) => e.isNotEmpty).toList();
    if (limit != null && items.length > limit) {
      return items.sublist(items.length - limit);
    }
    return items;
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove('audit_logs');
  }
}
