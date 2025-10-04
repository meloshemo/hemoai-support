import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/localization_service.dart';
import '../services/preferences_service.dart';
import '../services/push_notification_service.dart';
import '../services/backup_service.dart';
import '../services/analytics_service.dart';
import '../utils/backup_encryption.dart';
import '../utils/performance_optimizer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'restore_preview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Consumer<LocalizationService>(
      builder: (context, loc, _) {
        final canPop = Navigator.of(context).canPop();
        return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: canPop ? null : const AppDrawer(currentRoute: '/settings'),
        appBar: AppBar(
          leading: canPop
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop())
              : Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: theme.appBarTheme.foregroundColor ?? scheme.onSurface),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: loc.getString('menu'),
                  ),
                ),
          title: Text(loc.getString('settings')),
          backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
          foregroundColor: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              icon: Icons.person,
              title: loc.getString('settings_personal_data'),
              children: [
                _Tile(
                  icon: Icons.account_circle,
                  title: loc.getString('edit_profile'),
                  subtitle: loc.getString('edit_profile_desc'),
                  onTap: () => Navigator.pushNamed(context, '/personal_info'),
                ),
                _Tile(
                  icon: Icons.login,
                  title: loc.getString('account_login'),
                  subtitle: loc.getString('account_login_desc'),
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
              ],
            ),

            _Section(
              icon: Icons.privacy_tip,
              title: loc.getString('settings_privacy'),
              children: [
                _Tile(
                  icon: Icons.policy,
                  title: loc.getString('privacy_policy'),
                  subtitle: loc.getString('privacy_policy_desc'),
                  onTap: () => _showInfo(context, loc.getString('privacy_policy'), loc.getString('privacy_policy_body')),
                ),
                _Tile(
                  icon: Icons.gavel,
                  title: loc.getString('terms_of_use'),
                  subtitle: loc.getString('terms_of_use_desc'),
                  onTap: () => _showInfo(context, loc.getString('terms_of_use'), loc.getString('terms_of_use_body')),
                ),
                _SwitchTile(
                  icon: Icons.analytics_outlined,
                  title: loc.getString('analytics_opt_in'),
                  subtitle: loc.getString('analytics_opt_in_desc'),
                  prefKey: 'analytics_opt_in',
                  onChanged: (v) => Provider.of<AnalyticsService>(context, listen: false).setOptIn(v),
                ),
              ],
            ),

            _Section(
              icon: Icons.security,
              title: loc.getString('settings_security'),
              children: [
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  title: loc.getString('privacy_summary_title'),
                  subtitle: loc.getString('privacy_summary_desc'),
                  onTap: () => _showInfo(context, loc.getString('privacy_summary_title'), loc.getString('privacy_summary_body')),
                ),
                _SwitchTile(
                  icon: Icons.lock_outline,
                  title: loc.getString('app_lock'),
                  subtitle: loc.getString('app_lock_desc'),
                  prefKey: 'app_lock_enabled',
                ),
                _Tile(
                  icon: Icons.notifications_off,
                  title: loc.getString('clear_notifications'),
                  subtitle: loc.getString('clear_notifications_desc'),
                  onTap: () {
                    Provider.of<PushNotificationService>(context, listen: false).clearAllNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getString('done'))));
                  },
                ),
                _Tile(
                  icon: Icons.bug_report_outlined,
                  title: loc.getString('notification_debug_title'),
                  subtitle: loc.getString('notification_debug_desc'),
                  onTap: () => Navigator.pushNamed(context, '/notification_debug'),
                ),
              ],
            ),

            _Section(
              icon: Icons.storage,
              title: loc.getString('settings_data_backup'),
              children: [
                _Tile(
                  icon: Icons.verified_outlined,
                  title: loc.getString('trial_backup_title'),
                  subtitle: loc.getString('trial_backup_desc'),
                  onTap: () async {
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    final navigator = Navigator.of(context);
                    final theme = Theme.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final errSnack = SnackBar(content: Text(loc.getString('export_failed')), backgroundColor: theme.colorScheme.error);
                    analytics.trackEvent('trial_backup_start');
                    try {
                      final backup = await BackupService().exportAll();
                      analytics.trackEvent('trial_backup_ready', parameters: {'bytes': backup.length});
                      await navigator.push<bool>(
                        MaterialPageRoute(builder: (_) => RestorePreviewScreen(backupBytes: Uint8List.fromList(backup))),
                      );
                    } catch (e) {
                      analytics.trackEvent('trial_backup_failed', parameters: {'error': e.toString()});
                      messenger.showSnackBar(errSnack);
                    }
                  },
                ),
                _Tile(
                  icon: Icons.insights_outlined,
                  title: loc.getString('stats_overview_title'),
                  subtitle: loc.getString('stats_overview_desc'),
                  onTap: () => Navigator.pushNamed(context, '/stats'),
                ),
                _Tile(
                  icon: Icons.backup,
                  title: loc.getString('backup_data'),
                  subtitle: loc.getString('backup_data_desc'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final okText = loc.getString('export_success');
                    final errText = loc.getString('export_failed');
                    final backupReady = loc.getString('backup_ready');
                    final errorColor = Theme.of(context).colorScheme.error;
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    // Create JSON backup and share
                    final backup = await BackupService().exportAll();
                    final name = 'hemoai_backup_${DateTime.now().millisecondsSinceEpoch}.json';
                    try {
                      final x = XFile.fromData(Uint8List.fromList(backup), name: name, mimeType: 'application/json');
                      await Share.shareXFiles([x], text: backupReady);
                      // Analytics: backup shared
                      analytics.trackEvent('backup_shared', parameters: {'bytes': backup.length});
                      messenger.showSnackBar(
                        SnackBar(content: Text(okText), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      analytics.trackEvent('backup_share_failed', parameters: {'error': e.toString()});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(errText),
                          backgroundColor: errorColor,
                          action: SnackBarAction(
                            label: loc.getString('details'),
                            onPressed: () => _showErrorDetails(navigator.context, loc.getString('error_details'), e.toString()),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _Tile(
                  icon: Icons.lock_outline,
                  title: loc.getString('encrypted_backup'),
                  subtitle: loc.getString('encrypted_backup_desc'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final okText = loc.getString('export_success');
                    final errText = loc.getString('export_failed');
                    final errorColor = Theme.of(context).colorScheme.error;
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    // Ask for password + confirm
                    final pwd = await _askPassword(navigator.context, loc, confirm: true);
                    if (pwd == null) return;
                    try {
                      final backup = await BackupService().exportAll();
                      final enc = await BackupEncryption.encryptBytes(Uint8List.fromList(backup), pwd);
                      final name = 'hemoai_backup_${DateTime.now().millisecondsSinceEpoch}.hemoenc';
                      final x = XFile.fromData(enc, name: name, mimeType: 'application/octet-stream');
                      await Share.shareXFiles([x], text: loc.getString('encryption_enabled'));
                      analytics.trackEvent('backup_encrypted_shared', parameters: {'bytes': enc.length});
                      messenger.showSnackBar(SnackBar(content: Text(okText), backgroundColor: Colors.green));
                    } catch (e) {
                      analytics.trackEvent('backup_encrypted_failed', parameters: {'error': e.toString()});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(errText),
                          backgroundColor: errorColor,
                          action: SnackBarAction(
                            label: loc.getString('details'),
                            onPressed: () => _showErrorDetails(navigator.context, loc.getString('error_details'), e.toString()),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _Tile(
                  icon: Icons.restore,
                  title: loc.getString('restore_data'),
                  subtitle: loc.getString('restore_data_desc'),
                  onTap: () async {
                    // Pick JSON backup and restore
                    final messenger = ScaffoldMessenger.of(context);
                    final errorColor = Theme.of(context).colorScheme.error;
                    // Capture navigator after await-sensitive code to satisfy lints
                    final noFileText = loc.getString('no_file_selected');
                    final okText = loc.getString('export_success');
                    final errText = loc.getString('export_failed');
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    final navigator = Navigator.of(context);
                    try {
                      final res = await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        withData: true,
                        type: FileType.custom,
                        allowedExtensions: const ['json','hemoenc'],
                      );
                      if (res == null || res.files.isEmpty || res.files.single.bytes == null) {
                        analytics.trackEvent('restore_cancelled');
                        messenger.showSnackBar(SnackBar(content: Text(noFileText)));
                        return;
                      }
                      final file = res.files.single;
                      Uint8List bytes = file.bytes!;
                      if (file.name.endsWith('.hemoenc')) {
                        // Encrypted backup; ask password then decrypt before preview
                        if (!navigator.mounted) return;
                        final pwd = await _askPassword(navigator.context, loc, confirm: false);
                        if (pwd == null) return;
                        try {
                          bytes = await BackupEncryption.decryptBytes(bytes, pwd);
                        } catch (_) {
                          analytics.trackEvent('restore_decryption_failed');
                          if (!navigator.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(loc.getString('decryption_failed')),
                              backgroundColor: errorColor,
                              action: SnackBarAction(
                                label: loc.getString('details'),
                                onPressed: () => _showErrorDetails(navigator.context, loc.getString('error_details'), loc.getString('decryption_failed')),
                              ),
                            ),
                          );
                          return;
                        }
                      }
                      // Navigate to preview screen
                      if (!navigator.mounted) return;
                      final ok = await navigator.push<bool>(
                        MaterialPageRoute(builder: (_) => RestorePreviewScreen(backupBytes: bytes)),
                      );
                      if (ok == true && navigator.mounted) {
                        messenger.showSnackBar(SnackBar(content: Text(okText), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      analytics.trackEvent('restore_failed', parameters: {'error': e.toString()});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(errText),
                          backgroundColor: errorColor,
                          action: SnackBarAction(
                            label: loc.getString('details'),
                            onPressed: () => _showErrorDetails(navigator.context, loc.getString('error_details'), e.toString()),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _Tile(
                  icon: Icons.delete_forever,
                  title: loc.getString('delete_all_data'),
                  subtitle: loc.getString('delete_all_data_desc'),
                  onTap: () async {
                    final title = loc.getString('delete_all_data');
                    final confirmText = loc.getString('delete_all_data_confirm');
                    final deletedText = loc.getString('data_deleted');
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await _confirm(context, title, confirmText);
                    if (ok) {
                      final prefs = await PreferencesService.getInstance();
                      await prefs.clearAllData();
                      analytics.trackEvent('data_cleared');
                      messenger.showSnackBar(SnackBar(content: Text(deletedText)));
                    }
                  },
                ),
              ],
            ),

            _Section(
              icon: Icons.tune,
              title: loc.getString('performance_settings'),
              children: [
                _PerformanceAnimationTile(),
                _PerformanceMotionTile(),
                _Tile(
                  icon: Icons.cleaning_services,
                  title: loc.getString('clear_cache'),
                  subtitle: loc.getString('cache_management'),
                  onTap: () async {
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    analytics.trackEvent('cache_cleared_from_settings');
                    
                    try {
                      await PerformanceOptimizer().clearAllCaches();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.getString('cache_cleared'))),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${loc.getString('error')}: $e'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                _Tile(
                  icon: Icons.speed,
                  title: loc.getString('apply_recommended_settings'),
                  subtitle: loc.getString('optimize_for_device'),
                  onTap: () async {
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    analytics.trackEvent('performance_optimization_applied');
                    
                    try {
                      await PerformanceOptimizer().applyRecommendedSettings();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.getString('performance_optimized'))),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${loc.getString('error')}: $e'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                _Tile(
                  icon: Icons.settings_applications,
                  title: loc.getString('advanced_performance'),
                  subtitle: loc.getString('detailed_performance_controls'),
                  onTap: () {
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    analytics.trackEvent('performance_screen_opened');
                    Navigator.pushNamed(context, '/performance');
                  },
                ),
              ],
            ),

            _Section(
              icon: Icons.description_outlined,
              title: loc.getString('settings_legal'),
              children: [
                _Tile(
                  icon: Icons.info_outline,
                  title: loc.getString('about_hemoai'),
                  subtitle: loc.getString('app_description_detailed').length > 60 
                      ? '${loc.getString('app_description_detailed').substring(0, 60)}...'
                      : loc.getString('app_description_detailed'),
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
                _Tile(
                  icon: Icons.medical_information_outlined,
                  title: loc.getString('medical_disclaimer'),
                  subtitle: loc.getString('medical_disclaimer_desc'),
                  onTap: () => _showInfo(context, loc.getString('medical_disclaimer'), loc.getString('medical_disclaimer_body')),
                ),
                _Tile(
                  icon: Icons.support_agent,
                  title: loc.getString('help_support'),
                  subtitle: loc.getString('help_support_desc'),
                  onTap: () => _showInfo(context, loc.getString('help_support'), loc.getString('help_support_body')),
                ),
              ],
            ),
          ],
        ),
        );
      },
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          Consumer<LocalizationService>(
            builder: (_, loc, __) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.getString('close')),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDetails(BuildContext context, String title, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(details)),
        actions: [
          Consumer<LocalizationService>(
            builder: (_, loc, __) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.getString('close')),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.getString('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.getString('ok'))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _askPassword(BuildContext context, LocalizationService loc, {required bool confirm}) async {
    final controller = TextEditingController();
    final controller2 = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(confirm ? loc.getString('set_backup_password') : loc.getString('enter_backup_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: InputDecoration(labelText: loc.getString('password')),
                  ),
                  if (confirm) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller2,
                      obscureText: true,
                      decoration: InputDecoration(labelText: loc.getString('confirm_password')),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.getString('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final p1 = controller.text;
                    final p2 = controller2.text;
                    if (confirm && p1 != p2) {
                      setState(() => error = loc.getString('password_mismatch'));
                      return;
                    }
                    Navigator.pop(context, p1);
                  },
                  child: Text(loc.getString('ok')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section({required this.icon, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 8),
              Semantics(
                header: true,
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prefKey;
  final ValueChanged<bool>? onChanged;
  const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.prefKey, this.onChanged});
  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    setState(() {
      _value = prefs.getCustomSetting<bool>(widget.prefKey) ?? false;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool v) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.saveCustomSettings(widget.prefKey, v);
    if (mounted) setState(() => _value = v);
    // Side-effect callback (e.g., analytics opt-in)
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Semantics(
        container: true,
        label: widget.title,
        hint: widget.subtitle,
        toggled: _value,
        enabled: _loaded,
        onTap: _loaded ? () => _toggle(!_value) : null,
        child: ListTile(
          leading: Icon(widget.icon, color: scheme.primary),
          title: Text(widget.title),
          subtitle: Text(widget.subtitle),
          trailing: Switch(value: _value, onChanged: _loaded ? _toggle : null),
          onTap: _loaded ? () => _toggle(!_value) : null,
        ),
      ),
    );
  }
}

class _PerformanceAnimationTile extends StatefulWidget {
  const _PerformanceAnimationTile();
  @override
  State<_PerformanceAnimationTile> createState() => _PerformanceAnimationTileState();
}

class _PerformanceAnimationTileState extends State<_PerformanceAnimationTile> {
  bool _value = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PerformanceOptimizer().areAnimationsEnabled();
    if (mounted) {
      setState(() {
        _value = enabled;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    await PerformanceOptimizer().setAnimationsEnabled(v);
    if (mounted) setState(() => _value = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    
    return Card(
      child: ListTile(
        leading: Icon(Icons.animation, color: scheme.primary),
        title: Text(loc.getString('enable_animations')),
        subtitle: Text('${loc.getString('reduce_motion')} • ${_value ? "Enabled" : "Disabled"}'),
        trailing: Switch(value: _value, onChanged: _loaded ? _toggle : null),
        onTap: _loaded ? () => _toggle(!_value) : null,
      ),
    );
  }
}

class _PerformanceMotionTile extends StatefulWidget {
  const _PerformanceMotionTile();
  @override
  State<_PerformanceMotionTile> createState() => _PerformanceMotionTileState();
}

class _PerformanceMotionTileState extends State<_PerformanceMotionTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reduce = await PerformanceOptimizer().shouldReduceMotion();
    if (mounted) {
      setState(() {
        _value = reduce;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    await PerformanceOptimizer().setReduceMotion(v);
    if (mounted) setState(() => _value = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    
    return Card(
      child: ListTile(
        leading: Icon(Icons.accessibility, color: scheme.primary),
        title: Text(loc.getString('reduce_motion')),
        subtitle: Text('${loc.getString('auto_optimize')} • ${_value ? "Enabled" : "Disabled"}'),
        trailing: Switch(value: _value, onChanged: _loaded ? _toggle : null),
        onTap: _loaded ? () => _toggle(!_value) : null,
      ),
    );
  }
}
