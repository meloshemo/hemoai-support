import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../services/localization_service.dart';

/// Developer utility screen: automatically restore from the latest backup file
/// found in the user's Downloads folder (Windows/macOS/Linux desktop only),
/// then navigate to the dashboard.
class DevAutoRestoreScreen extends StatefulWidget {
  const DevAutoRestoreScreen({super.key});

  @override
  State<DevAutoRestoreScreen> createState() => _DevAutoRestoreScreenState();
}

class _DevAutoRestoreScreenState extends State<DevAutoRestoreScreen> {
  String _status = LocalizationService().getString('auto_restore_locating_backup');
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    try {
      // Skip auto-restore on web/mobile; jump to dashboard
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        setState(() => _status = loc.getString('auto_restore_not_supported'));
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }

      // Determine Downloads directory
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
      final downloads = Directory(
        Platform.isWindows ? '$home${Platform.pathSeparator}Downloads' : '$home${Platform.pathSeparator}Downloads',
      );
      if (!await downloads.exists()) {
        setState(() => _status = loc.getString('auto_restore_downloads_missing'));
        return;
      }

      // Find latest hemoai_backup_*.json
    final files = downloads
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'^hemoai_backup_.*\.json$').hasMatch(f.path.split(Platform.pathSeparator).last))
      .toList();

      if (files.isEmpty) {
        setState(() => _status = loc.getString('auto_restore_no_backup'));
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latest = files.first;
      setState(() => _status = loc.getString('auto_restore_reading_file').replaceAll('{path}', latest.path));

      final bytes = await latest.readAsBytes();

      // Summarize (optional)
      try {
        await BackupService().summarize(bytes.toList());
      } catch (_) {}

      setState(() => _status = loc.getString('auto_restore_restoring_replace'));
      final ok = await BackupService().restoreWithStrategy(bytes.toList(), strategy: 'replace');
      if (!mounted) return;
      setState(() => _status = ok ? loc.getString('export_success') : loc.getString('export_failed'));

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _done = true);
      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
        setState(() => _status =
          '${Provider.of<LocalizationService>(context, listen: false).getString('error_prefix')}${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = Provider.of<LocalizationService>(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('auto_restore_title'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_done) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(_status, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
