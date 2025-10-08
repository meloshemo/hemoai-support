import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'web_database_helper.dart';

/// Lightweight summary for a backup payload, used by the restore preview screen.
class BackupSummary {
  final String platform; // 'web' | 'native' (from backup file)
  final int preferencesCount;
  // Web store sections
  final int users;
  final int hemogramTests;
  final int familyMembers;
  final int familyInvitations;
  final int reminders;
  final int notifications;
  final int medications;
  final int water;
  final int dietEntries;

  const BackupSummary({
    required this.platform,
    required this.preferencesCount,
    required this.users,
    required this.hemogramTests,
    required this.familyMembers,
    required this.familyInvitations,
    required this.reminders,
    required this.notifications,
    required this.medications,
    required this.water,
    required this.dietEntries,
  });

  bool get isWeb => platform == 'web';
}

/// Backup/Restore all user-related data to a single JSON blob.
///
/// Scope (initial cut):
/// - Users, family members, invitations
/// - Hemogram tests
/// - Reminders, notifications, medications (per-user)
/// - Preference keys used by the app (theme, last_hemogram, settings)
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Export all data as pretty-printed JSON bytes (UTF-8)
  Future<List<int>> exportAll() async {
    final Map<String, dynamic> backup = {
      'schema': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'native',
      'data': <String, dynamic>{},
    };

    // Preferences snapshot (only app-specific keys)
    final prefs = await SharedPreferences.getInstance();
    final prefKeys = prefs.getKeys();
    final Map<String, dynamic> appPrefs = {};
    for (final k in prefKeys) {
      if (k.startsWith('user_') ||
          k.startsWith('custom_') ||
          k == 'current_user_id' ||
          k == 'last_hemogram' ||
          k == 'last_hemogram_date' ||
          k == 'notification_settings' ||
          k == 'dark_mode' ||
          k == 'first_launch' ||
          k.startsWith('water_') ||
          k.startsWith('medications')) {
        final v = prefs.get(k);
        if (v != null) appPrefs[k] = v;
      }
    }
    backup['data']['preferences'] = appPrefs;

    if (kIsWeb) {
      // Use WebDatabaseHelper's SharedPreferences storage
      final web = WebDatabaseHelper.instance;
      await web.init();
      // Directly access underlying prefs keys
      final SharedPreferences sp = (await SharedPreferences.getInstance());
      final keys = sp.getKeys();

      Map<String, dynamic> sections = {
        'users': _decodeStringList(sp.getStringList('users')),
        'hemogram_tests': _decodeStringList(sp.getStringList('hemogram_tests')),
        'family_members': _decodeStringList(sp.getStringList('family_members')),
        'family_invitations': _decodeStringList(sp.getStringList('family_invitations')),
      };

      // Collect per-user collections by prefix
      Map<String, dynamic> perUser = {
        'reminders': <String, dynamic>{},
        'notifications': <String, dynamic>{},
        'medications': <String, dynamic>{},
        'water': <String, dynamic>{},
        'diet': <String, dynamic>{},
      };
      for (final k in keys) {
        if (k.startsWith('reminders_')) {
          perUser['reminders'][k] = sp.getString(k);
        } else if (k.startsWith('notifications_')) {
          perUser['notifications'][k] = sp.getString(k);
        } else if (k.startsWith('medications_')) {
          perUser['medications'][k] = sp.getString(k);
        } else if (k.startsWith('water_')) {
          perUser['water'][k] = sp.getInt(k);
        } else if (k.startsWith('diet_')) {
          // diet_<userId>_<yyyy-MM-dd>
          final v = sp.getString(k);
          if (v != null) perUser['diet'][k] = v;
        }
      }
      sections['per_user'] = perUser;
      backup['data']['web_store'] = sections;
    } else {
      // Native (sqflite) — query known tables
      final dbh = DatabaseHelper.instance;
      final db = await dbh.database; // returns Database
      try {
        // Using rawQuery to avoid exposing all methods here
        final users = await db.rawQuery('SELECT * FROM users');
        final hemogram = await db.rawQuery('SELECT * FROM hemogram_tests');
        List<Map<String, Object?>> family = [];
        try {
          family = await db.rawQuery('SELECT * FROM family_members');
        } catch (_) {}
        List<Map<String, Object?>> reminders = [];
        try {
          reminders = await db.rawQuery('SELECT * FROM reminders');
        } catch (_) {}
        List<Map<String, Object?>> notifications = [];
        try {
          notifications = await db.rawQuery('SELECT * FROM notifications');
        } catch (_) {}
        List<Map<String, Object?>> dietTracking = [];
        try {
          dietTracking = await db.rawQuery('SELECT * FROM diet_tracking');
        } catch (_) {}

        backup['data']['native_db'] = {
          'users': users,
          'hemogram_tests': hemogram,
          'family_members': family,
          'reminders': reminders,
          'notifications': notifications,
          'diet_tracking': dietTracking,
        };
      } catch (e) {
  debugPrint('Backup (native) error while querying DB: $e');
      }
    }

    final jsonText = const JsonEncoder.withIndent('  ').convert(backup);
    return utf8.encode(jsonText);
  }

  /// Parse a backup JSON and return a compact summary for UI.
  Future<BackupSummary> summarize(List<int> jsonBytes) async {
    final text = utf8.decode(jsonBytes);
    final Map<String, dynamic> root = jsonDecode(text);
    final data = (root['data'] as Map).cast<String, dynamic>();
    final platform = (root['platform'] as String?) ?? 'native';

    int prefCount = 0;
    if (data['preferences'] is Map) {
      prefCount = (data['preferences'] as Map).length;
    }

    int users = 0,
        hemogramTests = 0,
        familyMembers = 0,
        familyInvitations = 0,
        reminders = 0,
        notifications = 0,
        medications = 0,
    water = 0,
    diet = 0;

    if (data['web_store'] is Map) {
      final webStore = (data['web_store'] as Map).cast<String, dynamic>();
      users = _len(webStore['users']);
      hemogramTests = _len(webStore['hemogram_tests']);
      familyMembers = _len(webStore['family_members']);
      familyInvitations = _len(webStore['family_invitations']);
      if (webStore['per_user'] is Map) {
        final pu = (webStore['per_user'] as Map).cast<String, dynamic>();
        reminders = _len((pu['reminders'] as Map?)?.values);
        notifications = _len((pu['notifications'] as Map?)?.values);
        medications = _len((pu['medications'] as Map?)?.values);
        water = _len((pu['water'] as Map?)?.values);
        diet = _len((pu['diet'] as Map?)?.values);
      }
    } else if (data['native_db'] is Map) {
      final native = (data['native_db'] as Map).cast<String, dynamic>();
      users = _len(native['users']);
      hemogramTests = _len(native['hemogram_tests']);
      familyMembers = _len(native['family_members']);
      reminders = _len(native['reminders']);
      notifications = _len(native['notifications']);
      diet = _len(native['diet_tracking']);
    }

    return BackupSummary(
      platform: platform,
      preferencesCount: prefCount,
      users: users,
      hemogramTests: hemogramTests,
      familyMembers: familyMembers,
      familyInvitations: familyInvitations,
      reminders: reminders,
      notifications: notifications,
      medications: medications,
      water: water,
      dietEntries: diet,
    );
  }

  int _len(dynamic v) {
    if (v is Iterable) return v.length;
    if (v is Map) return v.length;
    return 0;
  }

  /// Import data from previously exported JSON. Non-destructive: merges known sections.
  Future<bool> restoreAll(List<int> jsonBytes) async {
    try {
      final text = utf8.decode(jsonBytes);
      final Map<String, dynamic> root = jsonDecode(text);
      if (root['data'] is! Map<String, dynamic>) return false;
      final data = root['data'] as Map<String, dynamic>;

      // Restore preferences
      if (data.containsKey('preferences')) {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> p = (data['preferences'] as Map).cast<String, dynamic>();
        for (final entry in p.entries) {
          final v = entry.value;
          if (v is bool) {
            await prefs.setBool(entry.key, v);
          } else if (v is int) {
            await prefs.setInt(entry.key, v);
          } else if (v is double) {
            await prefs.setDouble(entry.key, v);
          } else if (v is String) {
            await prefs.setString(entry.key, v);
          } else if (v is List) {
            // Only support List<String> from our export
            final asStrings = v.whereType<String>().toList();
            await prefs.setStringList(entry.key, asStrings);
          }
        }
      }

      if (data.containsKey('web_store')) {
        final prefs = await SharedPreferences.getInstance();
        final webStore = (data['web_store'] as Map).cast<String, dynamic>();
        // Simple overwrite semantics for lists
        await _setIfListString(prefs, 'users', webStore['users']);
        await _setIfListString(prefs, 'hemogram_tests', webStore['hemogram_tests']);
        await _setIfListString(prefs, 'family_members', webStore['family_members']);
        await _setIfListString(prefs, 'family_invitations', webStore['family_invitations']);

        // Per-user buckets
        if (webStore['per_user'] is Map) {
          final perUser = (webStore['per_user'] as Map).cast<String, dynamic>();
          for (final entry in perUser.entries) {
            final group = entry.key; // reminders/notifications/medications/water
            if (entry.value is Map) {
              final m = (entry.value as Map).cast<String, dynamic>();
              for (final e in m.entries) {
                final key = e.key;
                final vv = e.value;
                if (group == 'water' && vv is int) {
                  await prefs.setInt(key, vv);
                } else if (vv is String) {
                  await prefs.setString(key, vv);
                }
              }
            }
          }
        }
      }

      // Native restore: for safety, we only target preferences by default.
      // DB merge could be added later with conflict checks.

      return true;
    } catch (e) {
      if (kDebugMode) {
  debugPrint('Restore error: $e');
      }
      return false;
    }
  }

  /// Strategy-aware restore used by the preview screen.
  /// strategy: 'replace' or 'merge'.
  Future<bool> restoreWithStrategy(List<int> jsonBytes, {String strategy = 'merge'}) async {
    try {
      final text = utf8.decode(jsonBytes);
      final Map<String, dynamic> root = jsonDecode(text);
      if (root['data'] is! Map<String, dynamic>) return false;
      final data = root['data'] as Map<String, dynamic>;

      // Preferences
      if (data.containsKey('preferences')) {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> p = (data['preferences'] as Map).cast<String, dynamic>();
        if (strategy == 'replace') {
          // Best-effort: clear only our app-specific keys (conservative)
          final keys = prefs.getKeys().where((k) =>
              k.startsWith('user_') ||
              k.startsWith('custom_') ||
              k == 'current_user_id' ||
              k == 'last_hemogram' ||
              k == 'last_hemogram_date' ||
              k == 'notification_settings' ||
              k == 'dark_mode' ||
              k == 'first_launch' ||
              k.startsWith('water_') ||
              k.startsWith('medications'));
          for (final k in keys) {
            await prefs.remove(k);
          }
        }
        // Apply incoming preferences (overwrite semantics for both strategies)
        for (final entry in p.entries) {
          final v = entry.value;
          if (v is bool) {
            await prefs.setBool(entry.key, v);
          } else if (v is int) {
            await prefs.setInt(entry.key, v);
          } else if (v is double) {
            await prefs.setDouble(entry.key, v);
          } else if (v is String) {
            await prefs.setString(entry.key, v);
          } else if (v is List) {
            final asStrings = v.whereType<String>().toList();
            await prefs.setStringList(entry.key, asStrings);
          }
        }
      }

      if (data.containsKey('web_store')) {
        final prefs = await SharedPreferences.getInstance();
        final webStore = (data['web_store'] as Map).cast<String, dynamic>();

        // Helper to apply list sections
        Future<void> applyList(String key, dynamic list) async {
          if (list is List) {
            if (strategy == 'replace') {
              final strings = list.map((e) => jsonEncode(e)).cast<String>().toList();
              await prefs.setStringList(key, strings);
            } else {
              // merge: union by id if present, else by serialized string
              final incoming = list.map((e) => e as Map).map((e) => e.cast<String, dynamic>()).toList();
              final existing = prefs.getStringList(key) ?? <String>[];
              final existingObjs = existing.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
              final byId = <String, Map<String, dynamic>>{};
              for (final m in existingObjs) {
                final id = m['id']?.toString();
                if (id != null) {
                  byId[id] = m;
                } else {
                  byId[jsonEncode(m)] = m;
                }
              }
              for (final m in incoming) {
                final id = m['id']?.toString();
                if (id != null) {
                  byId.putIfAbsent(id, () => m);
                } else {
                  byId.putIfAbsent(jsonEncode(m), () => m);
                }
              }
              final merged = byId.values.map((m) => jsonEncode(m)).toList();
              await prefs.setStringList(key, merged);
            }
          }
        }

        await applyList('users', webStore['users']);
        await applyList('hemogram_tests', webStore['hemogram_tests']);
        await applyList('family_members', webStore['family_members']);
        await applyList('family_invitations', webStore['family_invitations']);

        // Per-user maps (string or int values)
        if (webStore['per_user'] is Map) {
          final perUser = (webStore['per_user'] as Map).cast<String, dynamic>();
          for (final entry in perUser.entries) {
            final group = entry.key;
            if (entry.value is Map) {
              final m = (entry.value as Map).cast<String, dynamic>();
              for (final e in m.entries) {
                final key = e.key;
                final vv = e.value;
                if (strategy == 'replace') {
                  if (group == 'water' && vv is int) {
                    await prefs.setInt(key, vv);
                  } else if (vv is String) {
                    await prefs.setString(key, vv);
                  }
                } else {
                  // merge: write only if absent to avoid overwriting
                  if (group == 'water' && vv is int) {
                    if (!prefs.containsKey(key)) {
                      await prefs.setInt(key, vv);
                    }
                  } else if (vv is String) {
                    if (!prefs.containsKey(key)) {
                      await prefs.setString(key, vv);
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Native DB restore still limited to preferences for safety
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Restore (strategy) error: $e');
      }
      return false;
    }
  }

  List<Map<String, dynamic>> _decodeStringList(List<String>? list) {
    if (list == null) return [];
    return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> _setIfListString(SharedPreferences prefs, String key, dynamic value) async {
    if (value is List) {
      final strings = value.map((e) => jsonEncode(e)).cast<String>().toList();
      await prefs.setStringList(key, strings);
    }
  }
}
