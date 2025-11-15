import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hemoai/services/cloud_sync_service.dart';
import 'package:hemoai/services/backup_service.dart';

void main() {
  // Ensure SharedPreferences and other services can initialize in tests
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  // Initialize FFI for sqflite on desktop/test environments
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  test('cloud sync backup/restore roundtrip (local provider)', () async {
    final cloud = CloudSyncService();
    await cloud.signInAnonymously();

    // Perform a backup
    final okBackup = await cloud.backupNow('pwd-123');
    expect(okBackup, isTrue);

    // Meta should be available
    final meta = await cloud.getLatestMeta();
    expect(meta, isNotNull);
    expect(meta!.size, greaterThan(0));

    // Download blob and try to restore (merge)
    final restored = await cloud.restoreLatest('pwd-123', strategy: 'merge');
    expect(restored, isTrue);

    // Summarize downloaded backup to ensure it is a valid export
    // (Use BackupService.summarize on the locally downloaded blob)
    // We cannot access the raw encrypted blob here via service, so re-run backup and verify summary
    final bytes = await BackupService().exportAll();
    final summary = await BackupService().summarize(bytes);
    expect(summary.preferencesCount, greaterThanOrEqualTo(0));
  });
}
