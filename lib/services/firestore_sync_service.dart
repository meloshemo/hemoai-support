import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database_helper.dart';
import 'preferences_service.dart';
import '../utils/firestore_encryption.dart';

/// FirestoreSyncService
/// - Enables Firestore offline persistence
/// - Provides push/pull + snapshot listeners for key user subcollections
/// - Local-first: write immediately to SQLite, then enqueue push
/// - Conflict: last-write-wins via updatedAt (serverTimestamp)
class FirestoreSyncService extends ChangeNotifier {
  static final FirestoreSyncService _instance = FirestoreSyncService._internal();
  factory FirestoreSyncService() => _instance;
  FirestoreSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool get isEnabled => _enabledCache ?? false;
  bool? _enabledCache;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remindersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _hemogramsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _medicationsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _hydrationSub;

  static void ensurePersistence() {
    try {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    } catch (_) {
      // ignore (web or already set)
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Persistence already attempted in main; safe to call again
    ensurePersistence();

    // Start listeners if user and feature enabled
    await _startListenersIfEnabled();
  }

  /// Re-evaluate preferences and start/stop listeners accordingly.
  Future<void> refreshSync() async {
    // If not initialized yet, run full init (persistence + listeners).
    if (!_initialized) {
      await initialize();
      return;
    }
    await _startListenersIfEnabled();
  }

  Future<void> _startListenersIfEnabled() async {
    final prefs = await PreferencesService.getInstance();
    final enabled = prefs.getAutoCloudBackupEnabled(); // reuse existing toggle as cloud backup/sync flag
    _enabledCache = enabled;
    final userId = prefs.getCurrentUserId();
    if (!enabled || userId == null) {
      await disposeListeners();
      return;
    }

    // Ensure Firebase Auth session (anonymous) for rules to pass
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {
        // If sign-in fails, we still run local-only; listeners will fail until authenticated
      }
    }

    final uid = userId.toString();
    // Reminders
    _remindersSub ??= _db
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .listen((snap) async {
      final db = DatabaseHelper.instance;
      for (final doc in snap.docs) {
        var data = doc.data();
        // Decrypt sensitive text fields if encryption enabled
        data = await FirestoreEncryption.maybeDecryptMap(
          data,
          fields: const ['title', 'description'],
        );
        // Minimal merge strategy: insert if not present (title + scheduled_time), else ignore
        final existing = await db.getAllReminders(userId);
        final found = existing.any((e) =>
            (e['title']?.toString() ?? '') == (data['title']?.toString() ?? '') &&
            (e['scheduled_time']?.toString() ?? '') == (data['scheduled_time']?.toString() ?? ''));
        if (!found) {
          await db.createReminder({
            'user_id': userId,
            'title': data['title'],
            'description': data['description'],
            'scheduled_time': data['scheduled_time'],
            'type': data['type'] ?? 0,
            'repeat_type': data['repeat'] ?? 0,
            'is_active': data['is_active'] ?? 1,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
    });

    // Hemograms
    _hemogramsSub ??= _db
        .collection('users')
        .doc(uid)
        .collection('hemograms')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .listen((snap) async {
      final db = DatabaseHelper.instance;
      final existing = await db.getHemogramTests(userId);
      for (final doc in snap.docs) {
        var d = doc.data();
        d = await FirestoreEncryption.maybeDecryptMap(
          d,
          fields: const ['doctor_notes'],
        );
        final found = existing.any((e) =>
            (e['test_date']?.toString() ?? '') == (d['test_date']?.toString() ?? '') &&
            (e['hemoglobin']?.toString() ?? '') == (d['hemoglobin']?.toString() ?? ''));
        if (!found) {
          await db.insertHemogramTest({
            'user_id': userId,
            'test_date': d['test_date'],
            'hemoglobin': d['hemoglobin'],
            'iron': d['iron'],
            'leukocyte': d['leukocyte'],
            'erythrocyte': d['erythrocyte'],
            'hematocrit': d['hematocrit'],
            'platelet': d['platelet'],
            'mcv': d['mcv'],
            'mch': d['mch'],
            'mchc': d['mchc'],
            'rdw': d['rdw'],
            'neutrophil': d['neutrophil'],
            'lymphocyte': d['lymphocyte'],
            'monocyte': d['monocyte'],
            'eosinophil': d['eosinophil'],
            'basophil': d['basophil'],
            'values_json': d['values_json'],
            'risk_level': d['risk_level'],
            'doctor_notes': d['doctor_notes'],
          });
        }
      }
    });

    // Medications
    _medicationsSub ??= _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .listen((snap) async {
      final db = DatabaseHelper.instance;
      final existing = await db.getMedications(userId);
      for (final doc in snap.docs) {
        var m = doc.data();
        m = await FirestoreEncryption.maybeDecryptMap(
          m,
          fields: const ['name', 'dosage', 'frequency'],
        );
        final found = existing.any((e) =>
            (e['name']?.toString() ?? '') == (m['name']?.toString() ?? '') &&
            (e['start_date']?.toString() ?? '') == (m['start_date']?.toString() ?? ''));
        if (!found) {
          await db.insertMedication({
            'user_id': userId,
            'name': m['name'],
            'dosage': m['dosage'],
            'frequency': m['frequency'],
            'time_to_take': m['time_to_take'] ?? m['time'],
            'total_days': (m['total_days'] ?? 0),
            'completed_days': (m['completed_days'] ?? 0),
            'start_date': m['start_date'],
            'end_date': m['end_date'],
            'is_active': m['is_active'] ?? 1,
          });
        }
      }
    });

    // Hydration logs (water)
    _hydrationSub ??= _db
        .collection('users')
        .doc(uid)
        .collection('hydrationLogs')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .listen((snap) async {
      // For hydration, we update today's count if newer data exists
      final prefs = await PreferencesService.getInstance();
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = (data['date']?.toString() ?? '').substring(0, 10);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (date == today) {
          final count = (data['count'] as num?)?.toInt() ?? 0;
          await prefs.saveWaterCount(count);
        }
      }
    });
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.saveCustomSettings('auto_cloud_backup_enabled', value);
    _enabledCache = value;
    await refreshSync();
    notifyListeners();
  }

  Future<void> disposeListeners() async {
    await _remindersSub?.cancel();
    await _hemogramsSub?.cancel();
    await _medicationsSub?.cancel();
    await _hydrationSub?.cancel();
    _remindersSub = null;
    _hemogramsSub = null;
    _medicationsSub = null;
    _hydrationSub = null;
  }

  // ===== Push local data to Firestore (migration or on-demand) =====
  Future<void> migrateLocalToFirestore({required int userId}) async {
    final uid = userId.toString();
    final userDoc = _db.collection('users').doc(uid);

    // Hemograms
    final hemograms = await DatabaseHelper.instance.getHemogramTests(userId);
    for (final r in hemograms) {
      final id = (r['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString());
      final payload = await FirestoreEncryption.maybeEncryptMap({
        'userId': uid,
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
        'risk_level': r['risk_level'],
        'doctor_notes': r['doctor_notes'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, fields: const ['doctor_notes']);
      await userDoc.collection('hemograms').doc(id).set(
            payload,
            SetOptions(merge: true),
          );
    }

    // Medications
    final meds = await DatabaseHelper.instance.getMedications(userId);
    for (final m in meds) {
      final id = (m['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString());
      final payload = await FirestoreEncryption.maybeEncryptMap({
        'userId': uid,
        'name': m['name'],
        'dosage': m['dosage'],
        'frequency': m['frequency'],
        'time_to_take': m['time_to_take'],
        'total_days': m['total_days'],
        'completed_days': m['completed_days'] ?? 0,
        'start_date': m['start_date'],
        'end_date': m['end_date'],
        'is_active': m['is_active'] ?? 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, fields: const ['name', 'dosage', 'frequency']);
      await userDoc.collection('medications').doc(id).set(
            payload,
            SetOptions(merge: true),
          );
    }

    // Reminders
    final reminders = await DatabaseHelper.instance.getAllReminders(userId);
    for (final r in reminders) {
      final id = (r['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString());
      final payload = await FirestoreEncryption.maybeEncryptMap({
        'userId': uid,
        'title': r['title'],
        'description': r['description'],
        'scheduled_time': r['scheduled_time'],
        'type': r['type'],
        'repeat': r['repeat_type'] ?? 0,
        'is_active': r['is_active'] ?? 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, fields: const ['title', 'description']);
      await userDoc.collection('reminders').doc(id).set(
            payload,
            SetOptions(merge: true),
          );
    }

    // Hydration logs: push today only as a starting point
    final prefs = await PreferencesService.getInstance();
    final waterCount = prefs.getWaterCount();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await userDoc.collection('hydrationLogs').doc(today).set({
      'userId': uid,
      'date': today,
      'count': waterCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
