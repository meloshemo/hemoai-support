import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';

/// Runs a one-time auto-restore from the latest backup file found in the
/// user's Downloads folder on desktop platforms. No UI; best-effort only.
class AutoRestoreService {
  static const _doneKey = 'auto_restore_done';

  Future<void> runOnceAtStartup() async {
    try {
      if (kIsWeb) return;
      if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_doneKey) == true) return;

      final String? home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (home == null || home.isEmpty) return;
      final downloads = Directory('$home${Platform.pathSeparator}Downloads');
      if (!downloads.existsSync()) return;

      final files = downloads
          .listSync()
          .whereType<File>()
          .where((f) => RegExp(r'^hemoai_backup_.*\.json$')
              .hasMatch(f.path.split(Platform.pathSeparator).last))
          .toList();
      if (files.isEmpty) return;

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latest = files.first;
      debugPrint('AutoRestore: found backup ${latest.path}');

      final bytes = await latest.readAsBytes();
      final ok = await BackupService().restoreWithStrategy(bytes.toList(), strategy: 'replace');
      debugPrint('AutoRestore: restore result = $ok');
      if (ok) {
        await prefs.setBool(_doneKey, true);
      }
    } catch (e) {
      debugPrint('AutoRestore error: $e');
    }
  }
}
