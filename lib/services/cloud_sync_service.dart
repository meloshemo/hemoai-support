import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';
import '../utils/backup_encryption.dart';
import 'cloud_sync_config.dart';
import 'database_helper.dart';
import 'network_service.dart';
import 'localization_service.dart';

/// Minimal cloud-like sync built on top of BackupService + encrypted blob storage.
///
/// Goals in this initial slice:
/// - No network dependency; uses SharedPreferences as a storage provider to prove the flow
/// - Clear contract to swap with a real backend (Firebase/REST) later
/// - Platform-safe (works on web and native); guards behind helpers
///
/// Data contract:
/// - Each user has one latest encrypted backup blob
/// - Metadata includes timestamp and schema
/// - Conflict policy: last-write-wins for now (future: vector clock)
class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  late final CloudSyncProvider _provider = _selectProvider();

  String? _userId;
  String? get userId => _userId;
  bool get isSignedIn => _userId != null;

  DateTime? _lastBackupAt;
  DateTime? get lastBackupAt => _lastBackupAt;

  // Simple per-table sync API (initial slice): push/pull hemogram_tests only.
  // Local-first: write locally immediately; background sync uses LWW based on timestamps.
  Future<void> syncTables({required int userId}) async {
    // Only attempt if Supabase configured
    if (_provider is! SupabaseCloudSyncProvider) return;
    if (!CloudSyncConfig.isConfigured) {
      debugPrint('⚠️ Supabase not configured - skipping table sync');
      return;
    }
    try {
      // Hemogram tests
      await _pushHemogramTests(userId);
      await _pullHemogramTests(userId);
      // Reminders
      await _pushReminders(userId);
      await _pullReminders(userId);
      // Medications
      await _pushMedications(userId);
      await _pullMedications(userId);
      // Family members
      await _pushFamilyMembers(userId);
      await _pullFamilyMembers(userId);
    } catch (e) {
      debugPrint('Table sync error: $e');
    }
  }

  Future<void> signInAnonymously() async {
    // Persist a generated id to keep the experience stable across sessions
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('cloud_sync_user_id');
    if (_userId == null) {
      _userId = _randomId();
      await prefs.setString('cloud_sync_user_id', _userId!);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _userId = null;
    notifyListeners();
  }

  /// Export, encrypt and upload the latest backup snapshot.
  /// Returns true on success.
  Future<bool> backupNow(String password) async {
    if (_userId == null) await signInAnonymously();
    final uid = _userId!;

    try {
      // Skip network requirement for local Prefs provider (test/offline environments)
      final requiresNetwork = _provider is! PrefsCloudSyncProvider;
      if (requiresNetwork) {
        final networkService = NetworkService();
        if (!networkService.isInitialized) {
          await networkService.initialize();
        }
        if (!networkService.isConnected) {
          debugPrint('⚠️ No network connection - cannot backup');
          throw NetworkException(LocalizationService().getString('network_exception_no_connection'));
        }
      } else {
        debugPrint('ℹ️ Using local PrefsCloudSyncProvider - network check skipped');
      }

      final bytes = await BackupService().exportAll();
      final enc = await BackupEncryption.encryptBytes(Uint8List.fromList(bytes), password);
      final meta = {
        'ts': DateTime.now().toIso8601String(),
        'schema': 1,
        'platform': kIsWeb ? 'web' : 'native',
        'size': enc.length,
      };
      await _provider.uploadBackup(uid, enc, meta);
      _lastBackupAt = DateTime.now();
      notifyListeners();
      return true;
    } on NetworkException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      debugPrint('⚠️ CloudSync backup error: $e');
      if (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed')) {
        throw NetworkException(LocalizationService().getString('network_exception_connection_failed_vpn'));
      }
      return false;
    }
  }

  /// Download, decrypt and restore backup.
  Future<bool> restoreLatest(String password, {String strategy = 'merge'}) async {
    if (_userId == null) await signInAnonymously();
    final uid = _userId!;

    try {
      // Skip network requirement for local Prefs provider (test/offline environments)
      final requiresNetwork = _provider is! PrefsCloudSyncProvider;
      if (requiresNetwork) {
        final networkService = NetworkService();
        if (!networkService.isInitialized) {
          await networkService.initialize();
        }
        if (!networkService.isConnected) {
          debugPrint('⚠️ No network connection - cannot restore');
          throw NetworkException(LocalizationService().getString('network_exception_no_connection'));
        }
      } else {
        debugPrint('ℹ️ Using local PrefsCloudSyncProvider - network check skipped');
      }

      final data = await _provider.downloadBackup(uid);
      if (data == null) return false;
      final clear = await BackupEncryption.decryptBytes(data, password);
      return BackupService().restoreWithStrategy(clear.toList(), strategy: strategy);
    } on NetworkException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      debugPrint('⚠️ CloudSync restore error: $e');
      if (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed')) {
        throw NetworkException(LocalizationService().getString('network_exception_connection_failed_vpn'));
      }
      return false;
    }
  }

  Future<CloudBackupMeta?> getLatestMeta() async {
    if (_userId == null) await signInAnonymously();
    final uid = _userId!;
    return _provider.getMeta(uid);
  }

  String _randomId() {
    // 16-byte hex id
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = (i * 37 + DateTime.now().microsecondsSinceEpoch + i) & 0xff;
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

class CloudBackupMeta {
  final DateTime timestamp;
  final int schema;
  final String platform;
  final int size;
  CloudBackupMeta({required this.timestamp, required this.schema, required this.platform, required this.size});
}

abstract class CloudSyncProvider {
  Future<void> uploadBackup(String userId, Uint8List encryptedBytes, Map<String, dynamic> meta);
  Future<Uint8List?> downloadBackup(String userId);
  Future<CloudBackupMeta?> getMeta(String userId);
}

/// Preference-backed provider to simulate a remote store.
class PrefsCloudSyncProvider implements CloudSyncProvider {
  static String _blobKey(String userId) => 'cloud_blob_$userId';
  static String _metaKey(String userId) => 'cloud_meta_$userId';

  @override
  Future<Uint8List?> downloadBackup(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString(_blobKey(userId));
    if (b64 == null) return null;
    return Uint8List.fromList(base64Decode(b64));
  }

  @override
  Future<CloudBackupMeta?> getMeta(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_metaKey(userId));
    if (str == null) return null;
    final m = (jsonDecode(str) as Map).cast<String, dynamic>();
    return CloudBackupMeta(
      timestamp: DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      schema: (m['schema'] as num?)?.toInt() ?? 1,
      platform: (m['platform'] as String?) ?? 'native',
      size: (m['size'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> uploadBackup(String userId, Uint8List encryptedBytes, Map<String, dynamic> meta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_blobKey(userId), base64Encode(encryptedBytes));
    await prefs.setString(_metaKey(userId), jsonEncode(meta));
  }
}

/// Supabase-backed provider storing encrypted backups in Storage and metadata in a table.
class SupabaseCloudSyncProvider implements CloudSyncProvider {
  static const _metaTable = 'backups_meta';

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    if (!CloudSyncConfig.isConfigured) {
      debugPrint('⚠️ Supabase not configured - skipping initialization');
      _initialized = true; // Mark as initialized to prevent repeated checks
      return;
    }
    // Initialize once per process; subsequent calls are no-ops
    try {
      if (!Supabase.instance.isInitialized) {
        await Supabase.initialize(
          url: CloudSyncConfig.supabaseUrl,
          anonKey: CloudSyncConfig.supabaseAnonKey,
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      _initialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  String _storagePath(String userId) => 'backups/$userId/latest.hemoai.enc';

  @override
  Future<void> uploadBackup(String userId, Uint8List encryptedBytes, Map<String, dynamic> meta) async {
    await _ensureInit();
    if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
      debugPrint('⚠️ Supabase not configured - skipping backup upload');
      return;
    }
    // Try Storage first
    try {
      await _client.storage.from(CloudSyncConfig.storageBucket).uploadBinary(
            _storagePath(userId),
            encryptedBytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'application/octet-stream'),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
                throw TimeoutException(LocalizationService().getString('timeout_backup_upload'));
            },
          );
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('⚠️ Supabase storage upload timed out: $e');
        rethrow;
      } else if (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed')) {
        debugPrint('⚠️ Supabase storage upload connection error: $e');
          throw NetworkException(LocalizationService().getString('network_exception_connection_failed_vpn'));
      } else {
        debugPrint('⚠️ Supabase storage upload failed, will still write meta: $e');
        // Continue to try metadata write
      }
    }
    // Upsert metadata row
    try {
      final row = {
        'user_id': userId,
        'ts': meta['ts'] ?? DateTime.now().toIso8601String(),
        'platform': meta['platform'] ?? (kIsWeb ? 'web' : 'native'),
        'size': meta['size'] ?? encryptedBytes.length,
        'schema': meta['schema'] ?? 1,
      };
      await _client.from(_metaTable).upsert(row, onConflict: 'user_id').timeout(
        const Duration(seconds: 15),
        onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_metadata_update'));
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('⚠️ Supabase meta upsert timed out: $e');
        rethrow;
      } else if (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed')) {
        debugPrint('⚠️ Supabase meta upsert connection error: $e');
          throw NetworkException(LocalizationService().getString('network_exception_connection_failed_vpn'));
      } else {
        debugPrint('⚠️ Supabase meta upsert failed: $e');
        rethrow;
      }
    }
  }

  @override
  Future<Uint8List?> downloadBackup(String userId) async {
    await _ensureInit();
    if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
      debugPrint('⚠️ Supabase not configured - skipping backup download');
      return null;
    }
    try {
      final data = await _client.storage.from(CloudSyncConfig.storageBucket).download(_storagePath(userId)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_backup_download'));
        },
      );
      return data;
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('⚠️ Supabase storage download timed out: $e');
        rethrow;
      } else if (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed')) {
        debugPrint('⚠️ Supabase storage download connection error: $e');
          throw NetworkException(LocalizationService().getString('network_exception_connection_failed_vpn'));
      } else {
        debugPrint('⚠️ Supabase storage download failed: $e');
        return null;
      }
    }
  }

  @override
  Future<CloudBackupMeta?> getMeta(String userId) async {
    await _ensureInit();
    if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
      debugPrint('⚠️ Supabase not configured - skipping meta read');
      return null;
    }
    try {
      final rows = await _client.from(_metaTable).select().eq('user_id', userId).limit(1).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_metadata_read'));
        },
      );
      if (rows.isNotEmpty) {
        final m = (rows.first as Map).cast<String, dynamic>();
        return CloudBackupMeta(
          timestamp: DateTime.tryParse(m['ts']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
          schema: (m['schema'] as num?)?.toInt() ?? 1,
          platform: (m['platform'] as String?) ?? 'native',
          size: (m['size'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('⚠️ Supabase meta read timed out: $e');
        rethrow;
      } else if (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed')) {
        debugPrint('⚠️ Supabase meta read connection error: $e');
          throw NetworkException(LocalizationService().getString('network_exception_connection_failed_vpn'));
      } else {
        debugPrint('⚠️ Supabase meta read failed: $e');
      }
    }
    return null;
  }
}

extension on CloudSyncService {
  CloudSyncProvider _selectProvider() {
    if (CloudSyncConfig.isConfigured) {
      return SupabaseCloudSyncProvider();
    }
    return PrefsCloudSyncProvider();
  }
}

// ===== Table Sync helpers (initial hemogram_tests support) =====
extension _TableSync on CloudSyncService {
  Future<void> _pushHemogramTests(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping hemogram push');
        return;
      }
      
      final db = DatabaseHelper.instance;
      final rows = await db.getHemogramTests(userId);
      if (rows.isEmpty) return;
      // Prepare minimal records with LWW timestamp (created_at acts as last_updated for now)
      final List<Map<String, dynamic>> payload = rows.map((r) {
        return {
          'user_id': r['user_id'],
          'local_id': r['id'],
          'test_date': r['test_date'],
          'hemoglobin': r['hemoglobin'],
          'iron': r['iron'],
          'leukocyte': r['leukocyte'],
          'erythrocyte': r['erythrocyte'],
          'hematocrit': r['hematocrit'],
          'platelet': r['platelet'],
          'mcv': r['mcv'],
          'mch': r['mch'],
          'mchc': r['mchc'],
          'rdw': r['rdw'],
          'neutrophil': r['neutrophil'],
          'lymphocyte': r['lymphocyte'],
          'monocyte': r['monocyte'],
          'eosinophil': r['eosinophil'],
          'basophil': r['basophil'],
          'values_json': r['values_json'],
          'risk_level': r['risk_level'],
          'doctor_notes': r['doctor_notes'],
          'last_updated': (r['created_at'] ?? DateTime.now().toIso8601String()),
        };
      }).toList();

      final client = Supabase.instance.client;
      // Upsert by local_id (assuming it's unique per user)
      // If composite constraint doesn't exist, remove onConflict to use primary key
      try {
        await client.from('hemogram_tests').upsert(payload, onConflict: 'local_id').timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_hemogram_sync'));
          },
        );
      } catch (e) {
        if (e is TimeoutException || (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed'))) {
          debugPrint('⚠️ Hemogram sync connection/timeout error: $e');
          // Don't retry on connection errors
          return;
        }
        // Fallback: try without onConflict if constraint doesn't exist
        debugPrint('Upsert with onConflict failed, trying without: $e');
        try {
          await client.from('hemogram_tests').upsert(payload).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_hemogram_sync'));
            },
          );
        } catch (e2) {
          debugPrint('⚠️ Upsert without onConflict also failed: $e2');
        }
      }
    } catch (e) {
      debugPrint('Push hemogram_tests failed: $e');
    }
  }

  Future<void> _pullHemogramTests(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping hemogram pull');
        return;
      }
      final client = Supabase.instance.client;
      // Fetch all for user; filter by last_updated > last_sync if you track it (future improvement)
      final rows = await client
          .from('hemogram_tests')
          .select()
          .eq('user_id', userId)
          .order('last_updated', ascending: true)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_hemogram_pull'));
            },
          );
      final db = DatabaseHelper.instance;
      for (final row in rows.cast<Map>()) {
        final r = row.cast<String, dynamic>();
        // Merge into local DB using simple presence check by user_id+test_date or by values; we only insert if not present
        final existing = await db.getHemogramTests(userId);
        final found = existing.any((e) =>
            (e['test_date']?.toString() ?? '') == (r['test_date']?.toString() ?? '') &&
            (e['hemoglobin']?.toString() ?? '') == (r['hemoglobin']?.toString() ?? ''));
        if (!found) {
          final toInsert = {
            'user_id': userId,
            'test_date': r['test_date'],
            'hemoglobin': r['hemoglobin'],
            'iron': r['iron'],
            'leukocyte': r['leukocyte'],
            'erythrocyte': r['erythrocyte'],
            'hematocrit': r['hematocrit'],
            'platelet': r['platelet'],
            'mcv': r['mcv'],
            'mch': r['mch'],
            'mchc': r['mchc'],
            'rdw': r['rdw'],
            'neutrophil': r['neutrophil'],
            'lymphocyte': r['lymphocyte'],
            'monocyte': r['monocyte'],
            'eosinophil': r['eosinophil'],
            'basophil': r['basophil'],
            'values_json': r['values_json'],
            'risk_level': r['risk_level'],
            'doctor_notes': r['doctor_notes'],
          };
          await db.insertHemogramTest(toInsert);
        }
      }
    } catch (e) {
      debugPrint('Pull hemogram_tests failed: $e');
    }
  }

  // ===== Reminders =====
  Future<void> _pushReminders(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping reminders push');
        return;
      }
      final db = DatabaseHelper.instance;
      final rows = await db.getAllReminders(userId);
      if (rows.isEmpty) return;
      final payload = rows.map((r) {
        return {
          'user_id': r['user_id'] ?? userId,
          'local_id': r['id'],
          'title': r['title'],
          'description': r['description'],
          'scheduled_time': r['scheduled_time'],
          'type': r['type'],
          'repeat_type': r['repeat_type'] ?? 0,
          'is_active': r['is_active'] ?? 1,
          'last_updated': (r['created_at']?.toString() ?? DateTime.now().toIso8601String()),
        };
      }).toList();
      try {
        await Supabase.instance.client.from('reminders').upsert(payload, onConflict: 'local_id').timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_reminders_sync'));
          },
        );
      } catch (e) {
        if (e is TimeoutException || (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed'))) {
          debugPrint('⚠️ Reminders sync connection/timeout error: $e');
          return;
        }
        debugPrint('Reminders upsert with onConflict failed, trying without: $e');
        try {
          await Supabase.instance.client.from('reminders').upsert(payload).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_reminders_sync'));
            },
          );
        } catch (e2) {
          debugPrint('⚠️ Reminders upsert without onConflict also failed: $e2');
        }
      }
    } catch (e) {
      debugPrint('Push reminders failed: $e');
    }
  }

  Future<void> _pullReminders(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping reminders pull');
        return;
      }
      final client = Supabase.instance.client;
      final rows = await client
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .order('last_updated', ascending: true)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_reminders_pull'));
            },
          );
      final db = DatabaseHelper.instance;
      final existing = await db.getAllReminders(userId);
      for (final row in rows.cast<Map>()) {
        final r = row.cast<String, dynamic>();
        final found = existing.any((e) =>
            (e['title']?.toString() ?? '') == (r['title']?.toString() ?? '') &&
            (e['scheduled_time']?.toString() ?? '') == (r['scheduled_time']?.toString() ?? ''));
        if (!found) {
          final toInsert = {
            'user_id': userId,
            'title': r['title'],
            'description': r['description'],
            'scheduled_time': r['scheduled_time'],
            'type': r['type'] ?? 0,
            'repeat_type': r['repeat_type'] ?? 0,
            'is_active': r['is_active'] ?? 1,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          };
          await db.createReminder(toInsert);
        }
      }
    } catch (e) {
      debugPrint('Pull reminders failed: $e');
    }
  }

  // ===== Medications =====
  Future<void> _pushMedications(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping medications push');
        return;
      }
      final db = DatabaseHelper.instance;
      final rows = await db.getMedications(userId);
      if (rows.isEmpty) return;
      final payload = rows.map((r) {
        return {
          'user_id': r['user_id'] ?? userId,
          'local_id': r['id'],
          'name': r['name'],
          'dosage': r['dosage'],
          'frequency': r['frequency'],
          'time_to_take': r['time_to_take'],
          'total_days': r['total_days'],
          'completed_days': r['completed_days'] ?? 0,
          'start_date': r['start_date'],
          'end_date': r['end_date'],
          'is_active': r['is_active'] ?? 1,
          'last_updated': (r['created_at']?.toString() ?? DateTime.now().toIso8601String()),
        };
      }).toList();
      try {
        await Supabase.instance.client.from('medications').upsert(payload, onConflict: 'local_id').timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_medications_sync'));
          },
        );
      } catch (e) {
        if (e is TimeoutException || (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed'))) {
          debugPrint('⚠️ Medications sync connection/timeout error: $e');
          return;
        }
        debugPrint('Medications upsert with onConflict failed, trying without: $e');
        try {
          await Supabase.instance.client.from('medications').upsert(payload).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_medications_sync'));
            },
          );
        } catch (e2) {
          debugPrint('⚠️ Medications upsert without onConflict also failed: $e2');
        }
      }
    } catch (e) {
      debugPrint('Push medications failed: $e');
    }
  }

  Future<void> _pullMedications(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping medications pull');
        return;
      }
      final client = Supabase.instance.client;
      final rows = await client
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('last_updated', ascending: true)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_medications_pull'));
            },
          );
      final db = DatabaseHelper.instance;
      final existing = await db.getMedications(userId);
      for (final row in rows.cast<Map>()) {
        final r = row.cast<String, dynamic>();
        final found = existing.any((e) =>
            (e['name']?.toString() ?? '') == (r['name']?.toString() ?? '') &&
            (e['start_date']?.toString() ?? '') == (r['start_date']?.toString() ?? ''));
        if (!found) {
          final toInsert = {
            'user_id': userId,
            'name': r['name'],
            'dosage': r['dosage'],
            'frequency': r['frequency'],
            'time_to_take': r['time_to_take'],
            'total_days': r['total_days'] ?? 0,
            'completed_days': r['completed_days'] ?? 0,
            'start_date': r['start_date'],
            'end_date': r['end_date'],
            'is_active': r['is_active'] ?? 1,
          };
          await db.insertMedication(toInsert);
        }
      }
    } catch (e) {
      debugPrint('Pull medications failed: $e');
    }
  }

  // ===== Family members =====
  Future<void> _pushFamilyMembers(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping family members push');
        return;
      }
      final db = DatabaseHelper.instance;
      final rows = await db.getFamilyMembers(userId);
      if (rows.isEmpty) return;
      final payload = rows.map((r) {
        return {
          'user_id': r['user_id'] ?? userId,
          'local_id': r['id'],
          'name': r['name'],
          'relation': r['relation'],
          'age': r['age'],
          'gender': r['gender'],
          'avatar': r['avatar'],
          'last_updated': (r['created_at']?.toString() ?? DateTime.now().toIso8601String()),
        };
      }).toList();
      try {
        await Supabase.instance.client.from('family_members').upsert(payload, onConflict: 'local_id').timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(LocalizationService().getString('timeout_family_members_sync'));
          },
        );
      } catch (e) {
        if (e is TimeoutException || (e.toString().contains('Connection') || e.toString().contains('network') || e.toString().contains('failed'))) {
          debugPrint('⚠️ Family members sync connection/timeout error: $e');
          return;
        }
        debugPrint('Family members upsert with onConflict failed, trying without: $e');
        try {
          await Supabase.instance.client.from('family_members').upsert(payload).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_family_members_sync'));
            },
          );
        } catch (e2) {
          debugPrint('⚠️ Family members upsert without onConflict also failed: $e2');
        }
      }
    } catch (e) {
      debugPrint('Push family_members failed: $e');
    }
  }

  Future<void> _pullFamilyMembers(int userId) async {
    try {
      if (_provider is! SupabaseCloudSyncProvider) return;
      if (!CloudSyncConfig.isConfigured || !Supabase.instance.isInitialized) {
        debugPrint('⚠️ Supabase not configured - skipping family members pull');
        return;
      }
      final client = Supabase.instance.client;
      final rows = await client
          .from('family_members')
          .select()
          .eq('user_id', userId)
          .order('last_updated', ascending: true)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(LocalizationService().getString('timeout_family_members_pull'));
            },
          );
      final db = DatabaseHelper.instance;
      final existing = await db.getFamilyMembers(userId);
      for (final row in rows.cast<Map>()) {
        final r = row.cast<String, dynamic>();
        final found = existing.any((e) =>
            (e['name']?.toString() ?? '') == (r['name']?.toString() ?? '') &&
            (e['relation']?.toString() ?? '') == (r['relation']?.toString() ?? '') &&
            (e['age']?.toString() ?? '') == (r['age']?.toString() ?? ''));
        if (!found) {
          final toInsert = {
            'user_id': userId,
            'name': r['name'],
            'relation': r['relation'],
            'age': r['age'],
            'gender': r['gender'],
            'avatar': r['avatar'],
          };
          await db.insertFamilyMember(toInsert);
        }
      }
    } catch (e) {
      debugPrint('Pull family_members failed: $e');
    }
  }
}
