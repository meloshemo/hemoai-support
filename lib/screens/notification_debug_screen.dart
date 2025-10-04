import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/push_notification_service.dart';
import '../services/localization_service.dart';

class NotificationDebugScreen extends StatelessWidget {
  const NotificationDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return Consumer<PushNotificationService>(
      builder: (context, push, _) {
        final scheduled = push.scheduledNotifications;
        final received = push.receivedNotifications;
        final logs = push.debugLogs;
        return Scaffold(
          appBar: AppBar(
            title: Text(loc.getString('notification_debug_title')),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(loc.getString('notification_debug_scheduled'), style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                _Box(
                  child: scheduled.isEmpty
                      ? Text(loc.getString('none'))
                      : Column(
                          children: [
                            for (final s in scheduled)
                              Semantics(
                                label: s.title,
                                hint: '${s.scheduledTime.toIso8601String()} | ${s.type.name}',
                                child: ListTile(
                                  dense: true,
                                  title: Text(s.title),
                                  subtitle: Text(
                                    '${s.scheduledTime.toIso8601String()} | ${s.type.name}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: loc.getString('cancel'),
                                    icon: const Icon(Icons.cancel_outlined),
                                    onPressed: () => push.cancelNotification(s.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(loc.getString('notification_debug_received'), style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                _Box(
                  child: received.isEmpty
                      ? Text(loc.getString('none'))
                      : Column(
                          children: [
                            for (final m in received)
                              Semantics(
                                label: m.title,
                                hint: '${m.receivedAt.toIso8601String()} | ${m.type.name}',
                                child: ListTile(
                                dense: true,
                                leading: Icon(m.isRead ? Icons.mark_email_read : Icons.mark_email_unread),
                                title: Text(m.title),
                                subtitle: Text('${m.receivedAt.toIso8601String()} | ${m.type.name}'),
                                trailing: Wrap(spacing: 8, children: [
                                  IconButton(
                                    tooltip: loc.getString('mark_read'),
                                    icon: const Icon(Icons.done),
                                    onPressed: m.isRead ? null : () => push.markAsRead(m.id),
                                  ),
                                  IconButton(
                                    tooltip: loc.getString('why_did_i_get_this'),
                                    icon: const Icon(Icons.help_outline),
                                    onPressed: () {
                                      final reason = push.getNotificationReason(m.id);
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(loc.getString('why_did_i_get_this')),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _kv(loc.getString('reason_scheduled_time'), reason['scheduled_time']),
                                                _kv(loc.getString('reason_received_at'), reason['received_at']),
                                                _kv(loc.getString('reason_repeat'), reason['repeat']),
                                                _kv(loc.getString('reason_reminder_id'), reason['reminder_id']),
                                                _kv(loc.getString('reason_category'), reason['category']),
                                                _kv(loc.getString('reason_hour'), reason['hour']),
                                                _kv(loc.getString('reason_minute'), reason['minute']),
                                                _kv(loc.getString('reason_device_token'), reason['device_token']),
                                                _kv(loc.getString('reason_permission_granted'), reason['permission_granted']),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(loc.getString('close')),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ]),
                              )),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(loc.getString('notification_debug_logs'), style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _Box(
                    child: logs.isEmpty
                        ? Text(loc.getString('none'))
                        : ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (context, i) {
                              final e = logs[logs.length - 1 - i]; // show latest first
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.bug_report_outlined),
                                title: Text(e.message),
                                subtitle: Text(e.timestamp.toIso8601String()),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;
  const _Box({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

Widget _kv(String label, Object? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text('${value ?? '-'}'),
      ],
    ),
  );
}
