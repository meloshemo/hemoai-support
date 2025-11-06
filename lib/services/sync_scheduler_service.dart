import 'dart:async';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';
import 'cloud_sync_service.dart';

/// Periodically triggers cloud backups when enabled and password is set.
/// Runs only while the app is active (foreground). On the web, it uses timers; no system background.
class SyncSchedulerService extends ChangeNotifier {
  Timer? _timer;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Stagger first run to avoid busy startup
    _scheduleImmediateCheck();

    // Run periodic checks every 6 hours
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _runIfDue());
  }

  Future<void> _scheduleImmediateCheck() async {
    // small delay for startup services to settle
    Future.delayed(const Duration(seconds: 5), _runIfDue);
  }

  Future<void> _runIfDue() async {
    try {
      final prefs = await PreferencesService.getInstance();
      final enabled = prefs.getAutoCloudBackupEnabled();
      final password = await prefs.getCloudBackupPasswordAsync();
      if (!enabled || password == null || password.isEmpty) return;

      final last = prefs.getLastAutoCloudBackup();
      final now = DateTime.now();
      final due = (last == null) || now.difference(last) > const Duration(hours: 24);
      if (!due) return;

      final ok = await CloudSyncService().backupNow(password);
      if (ok) {
        await prefs.setLastAutoCloudBackup(DateTime.now());
        // Also run lightweight per-table sync if configured (no-op for Prefs provider)
        final userId = prefs.getCurrentUserId();
        if (userId != null) {
          // Fire-and-forget table sync after a successful backup (Supabase only)
          unawaited(CloudSyncService().syncTables(userId: userId));
        }
        notifyListeners();
      }
    } catch (_) {
      // ignore scheduler errors; will try later
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
