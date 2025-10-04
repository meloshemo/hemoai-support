import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../services/localization_service.dart';
import '../services/analytics_service.dart';

class RestorePreviewScreen extends StatefulWidget {
  final Uint8List backupBytes;
  const RestorePreviewScreen({super.key, required this.backupBytes});

  @override
  State<RestorePreviewScreen> createState() => _RestorePreviewScreenState();
}

class _RestorePreviewScreenState extends State<RestorePreviewScreen> {
  BackupSummary? _summary;
  bool _busy = false;
  String _strategy = 'merge'; // 'merge' | 'replace'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await BackupService().summarize(widget.backupBytes.toList());
    if (mounted) setState(() => _summary = s);
  }

  Future<void> _doRestore() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final okText = loc.getString('export_success');
    final errText = loc.getString('export_failed');
    final errorColor = Theme.of(context).colorScheme.error;
    setState(() => _busy = true);
    try {
      final ok = await BackupService().restoreWithStrategy(widget.backupBytes.toList(), strategy: _strategy);
      analytics.trackEvent('restore_preview_apply', parameters: { 'strategy': _strategy, 'success': ok });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? okText : errText), backgroundColor: ok ? Colors.green : errorColor),
      );
      if (ok && mounted) Navigator.pop(context, true);
    } catch (e) {
      analytics.trackEvent('restore_preview_failed', parameters: { 'error': e.toString() });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errText),
          backgroundColor: errorColor,
          action: SnackBarAction(
            label: loc.getString('details'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.getString('error_details')),
                  content: SingleChildScrollView(child: Text(e.toString())),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(loc.getString('close')),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('restore_preview'))),
      body: _summary == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(loc.getString('backup_overview'), style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  _Row(label: loc.getString('backup_platform'), value: _summary!.platform),
                  _Row(label: loc.getString('preferences'), value: _summary!.preferencesCount.toString()),
                  const Divider(height: 24),
                  if (_summary!.isWeb) ...[
                    _Row(label: loc.getString('users'), value: _summary!.users.toString()),
                    _Row(label: loc.getString('hemogram_tests'), value: _summary!.hemogramTests.toString()),
                    _Row(label: loc.getString('family_members'), value: _summary!.familyMembers.toString()),
                    _Row(label: loc.getString('family_invitations'), value: _summary!.familyInvitations.toString()),
                    _Row(label: loc.getString('reminders'), value: _summary!.reminders.toString()),
                    _Row(label: loc.getString('notifications'), value: _summary!.notifications.toString()),
                    _Row(label: loc.getString('medications'), value: _summary!.medications.toString()),
                    _Row(label: loc.getString('water'), value: _summary!.water.toString()),
                  ],
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(loc.getString('restore_strategy'), style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: loc.getString('restore_strategy'),
                    child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'merge',
                        label: Text(loc.getString('restore_merge')),
                        icon: const Icon(Icons.merge_type),
                      ),
                      ButtonSegment(
                        value: 'replace',
                        label: Text(loc.getString('restore_replace')),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {_strategy},
                    onSelectionChanged: _busy
                        ? null
                        : (selection) {
                            final newStrategy = selection.first;
                            if (newStrategy != _strategy) {
                              setState(() => _strategy = newStrategy);
                              analytics.trackEvent('restore_strategy_changed', parameters: {'strategy': newStrategy});
                            }
                          },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _strategy == 'merge' ? loc.getString('restore_merge_desc') : loc.getString('restore_replace_desc'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      button: true,
                      enabled: !_busy,
                      label: loc.getString('apply_restore'),
                      child: Tooltip(
                        message: loc.getString('apply_restore'),
                        child: ElevatedButton.icon(
                      onPressed: _busy ? null : _doRestore,
                      icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                      label: Text(loc.getString('apply_restore')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
