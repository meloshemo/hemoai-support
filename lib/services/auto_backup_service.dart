import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';
import 'preferences_service.dart';

/// Automatic backup scheduler service
/// Handles periodic encrypted backups to cloud storage
class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  static const String _lastBackupKey = 'auto_backup_last_run';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _backupIntervalHoursKey = 'auto_backup_interval_hours';
  
  /// Default backup interval: 24 hours
  static const int defaultBackupIntervalHours = 24;

  /// Check if auto backup is enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? true; // Default: enabled
  }

  /// Enable/disable auto backup
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    if (kDebugMode) {
      debugPrint('📦 Auto backup ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Get backup interval in hours
  Future<int> getBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_backupIntervalHoursKey) ?? defaultBackupIntervalHours;
  }

  /// Set backup interval in hours
  Future<void> setBackupInterval(int hours) async {
    if (hours < 1) hours = 1; // Minimum 1 hour
    if (hours > 168) hours = 168; // Maximum 1 week
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backupIntervalHoursKey, hours);
    if (kDebugMode) {
      debugPrint('📦 Auto backup interval set to $hours hours');
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastBackupKey);
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  /// Check if backup is due
  Future<bool> isBackupDue() async {
    if (!await isEnabled()) return false;
    
    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return true; // Never backed up
    
    final interval = await getBackupInterval();
    final nextBackup = lastBackup.add(Duration(hours: interval));
    return DateTime.now().isAfter(nextBackup);
  }

  /// Perform automatic backup if due
  /// Returns true if backup was performed, false if skipped
  Future<bool> checkAndBackupIfDue(String password) async {
    try {
      if (!await isBackupDue()) {
        if (kDebugMode) {
          debugPrint('📦 Auto backup skipped (not due yet)');
        }
        return false;
      }

      final cloudSync = CloudSyncService();
      final success = await cloudSync.backupNow(password);
      
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
        if (kDebugMode) {
          debugPrint('✅ Auto backup completed successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Auto backup failed');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Auto backup error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Force immediate backup (manual trigger)
  Future<bool> backupNow(String password) async {
    try {
      final cloudSync = CloudSyncService();
      final success = await cloudSync.backupNow(password);
      
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
        if (kDebugMode) {
          debugPrint('✅ Manual backup completed successfully');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Manual backup error: $e');
      }
      return false;
    }
  }

  /// Get time until next backup
  Future<Duration?> getTimeUntilNextBackup() async {
    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return null;
    
    final interval = await getBackupInterval();
    final nextBackup = lastBackup.add(Duration(hours: interval));
    final now = DateTime.now();
    
    if (now.isAfter(nextBackup)) {
      return Duration.zero; // Due now
    }
    
    return nextBackup.difference(now);
  }
}

