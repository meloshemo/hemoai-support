import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart' as ns;
import '../widgets/app_drawer.dart';
import '../services/localization_service.dart';
import 'add_reminder_screen.dart';
import '../services/audit_log_service.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';
import '../services/push_notification_service.dart' as ps;
import '../services/database_helper.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ns.NotificationItem> _allReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationService =
          Provider.of<ns.NotificationService>(context, listen: false);
      setState(() {
        _allReminders = notificationService.notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ns.NotificationItem> get _upcomingReminders {
    final now = DateTime.now();
    return _allReminders
        .where((r) => r.isActive && r.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  List<ns.NotificationItem> get _overdueReminders {
    final now = DateTime.now();
    return _allReminders
        .where((r) => r.isActive && r.scheduledTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  List<ns.NotificationItem> get _completedReminders {
    return _allReminders.where((r) => !r.isActive).toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  String _getTypeDisplayName(ns.NotificationType type) {
    switch (type) {
      case ns.NotificationType.medication:
        return Provider.of<LocalizationService>(context, listen: false)
            .getString('reminder_type_medication');
      case ns.NotificationType.test:
        return Provider.of<LocalizationService>(context, listen: false)
            .getString('reminder_type_test');
      case ns.NotificationType.appointment:
        return Provider.of<LocalizationService>(context, listen: false)
            .getString('reminder_type_appointment');
      case ns.NotificationType.reminder:
        return Provider.of<LocalizationService>(context, listen: false)
            .getString('reminder_type_general_reminder');
      case ns.NotificationType.general:
        return Provider.of<LocalizationService>(context, listen: false)
            .getString('reminder_type_general');
    }
  }

  IconData _getTypeIcon(ns.NotificationType type) {
    switch (type) {
      case ns.NotificationType.medication:
        return Icons.medication;
      case ns.NotificationType.test:
        return Icons.science;
      case ns.NotificationType.appointment:
        return Icons.event;
      case ns.NotificationType.reminder:
        return Icons.alarm;
      case ns.NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(ns.NotificationType type) {
    switch (type) {
      case ns.NotificationType.medication:
        return Colors.green;
      case ns.NotificationType.test:
        return Colors.blue;
      case ns.NotificationType.appointment:
        return Colors.orange;
      case ns.NotificationType.reminder:
        return const Color(0xFFE53E3E);
      case ns.NotificationType.general:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final locSvc = Provider.of<LocalizationService>(context, listen: false);

    if (difference.inDays == 0) {
      return '${locSvc.getString('date_today')} ${locSvc.formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return '${locSvc.getString('date_tomorrow')} ${locSvc.formatTime(dateTime)}';
    } else if (difference.inDays == -1) {
      return '${locSvc.getString('date_yesterday')} ${locSvc.formatTime(dateTime)}';
    } else {
      return '${locSvc.formatDate(dateTime)} ${locSvc.formatTime(dateTime)}';
    }
  }

  void _showReminderDetails(ns.NotificationItem reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getTypeColor(reminder.type)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(reminder.type),
                            color: _getTypeColor(reminder.type),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTypeDisplayName(reminder.type),
                                style: TextStyle(
                                  color: _getTypeColor(reminder.type),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                Provider.of<LocalizationService>(context,
                                        listen: false)
                                    .getString('reminder_time_label'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(reminder.scheduledTime),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getString('reminder_description_heading'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reminder.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // Mark as Done -> log, update streak, reschedule if repeating
                              Navigator.pop(context);
                              await _markAsDone(reminder);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getString('mark_as_done')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getString('snooze'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _snoozeReminder(
                                  reminder, const Duration(minutes: 10));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getString('snoozed_for_10'))),
                              );
                            },
                            icon: const Icon(Icons.snooze, size: 18),
                            label: Text(Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getString('snooze_10m')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _snoozeReminder(
                                  reminder, const Duration(minutes: 30));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getString('snoozed_for_30'))),
                              );
                            },
                            icon: const Icon(Icons.snooze, size: 18),
                            label: Text(Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getString('snooze_30m')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _dismissReminderForToday(reminder);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getString('dismissed_for_today'))),
                              );
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getString('snooze_dismiss_today')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleReminder(reminder);
                            },
                            icon: Icon(reminder.isActive
                                ? Icons.pause
                                : Icons.play_arrow),
                            label: Text(reminder.isActive
                                ? Provider.of<LocalizationService>(context,
                                        listen: false)
                                    .getString('reminder_action_pause')
                                : Provider.of<LocalizationService>(context,
                                        listen: false)
                                    .getString('reminder_action_activate')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteReminder(reminder);
                            },
                            icon: const Icon(Icons.delete),
                            label: Text(Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getString('delete')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDone(ns.NotificationItem reminder) async {
    try {
      if (reminder.id == null) return;
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      final db = DatabaseHelper.instance;
      // Update streaks
      final streak = await db.getReminderStreak(reminder.id!, userId: userId);
      final last = streak['last_completed_date'] as String?;
      final today = DateTime.now().toIso8601String().split('T')[0];
      int current = (streak['current_streak'] as int? ?? 0);
      int longest = (streak['longest_streak'] as int? ?? 0);
      if (last == null) {
        current = 1;
      } else {
        // if last was yesterday -> +1; if today -> keep; else reset to 1
        final yesterday = DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0];
        if (last == today) {
          // already counted
        } else if (last == yesterday) {
          current = current + 1;
        } else {
          current = 1;
        }
      }
      if (current > longest) longest = current;
      await db.upsertReminderStreak(
        reminderId: reminder.id!,
        userId: userId,
        currentStreak: current,
        longestStreak: longest,
        lastCompletedDate: today,
      );

      // Log action
      await db.insertReminderLog(
        reminderId: reminder.id!,
        userId: userId,
        action: 'done',
        actionDate: DateTime.now(),
        scheduledTime: reminder.scheduledTime,
      );

      // Reschedule next occurrence if repeating; otherwise deactivate
      final notificationService =
          Provider.of<ns.NotificationService>(context, listen: false);
      DateTime? next;
      switch (reminder.repeatType) {
        case ns.RepeatType.none:
          await notificationService.toggleNotification(reminder.id!);
          break;
        case ns.RepeatType.daily:
          next = reminder.scheduledTime.add(const Duration(days: 1));
          break;
        case ns.RepeatType.weekly:
          next = reminder.scheduledTime.add(const Duration(days: 7));
          break;
        case ns.RepeatType.monthly:
          next = DateTime(
              reminder.scheduledTime.year,
              reminder.scheduledTime.month + 1,
              reminder.scheduledTime.day,
              reminder.scheduledTime.hour,
              reminder.scheduledTime.minute);
          break;
      }
      if (next != null) {
        await notificationService.updateScheduledTime(reminder.id!, next);
        // Also push-notification mapping
        final push =
            Provider.of<ps.PushNotificationService>(context, listen: false);
        String repeatStr = 'none';
        switch (reminder.repeatType) {
          case ns.RepeatType.daily:
            repeatStr = 'daily';
            break;
          case ns.RepeatType.weekly:
            repeatStr = 'weekly';
            break;
          case ns.RepeatType.monthly:
            repeatStr = 'monthly';
            break;
          case ns.RepeatType.none:
            repeatStr = 'none';
            break;
        }
        await push.scheduleNotification(
          title: reminder.title,
          body: reminder.description,
          scheduledTime: next,
          type: _mapReminderTypeToPush(reminder.type),
          data: {
            'repeat': repeatStr,
            'hour': next.hour,
            'minute': next.minute,
            'reminder_id': reminder.id,
            'source': 'mark_done',
          },
        );
      }
      AuditLogService()
          .logAction('reminder_mark_done', data: {'id': reminder.id});
      if (!mounted) return;
      _loadReminders();
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  Future<void> _dismissReminderForToday(ns.NotificationItem reminder) async {
    try {
      if (reminder.id == null) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      final db = DatabaseHelper.instance;
      final notificationService =
          Provider.of<ns.NotificationService>(context, listen: false);

      // Log the dismiss action
      await db.insertReminderLog(
        reminderId: reminder.id!,
        userId: userId,
        action: 'dismiss_today',
        actionDate: now,
        scheduledTime: null,
        metadata: jsonEncode({'dismissed_date': today.toIso8601String()}),
      );

      // If repeating, reschedule for tomorrow
      if (reminder.repeatType != ns.RepeatType.none) {
        DateTime? next;
        switch (reminder.repeatType) {
          case ns.RepeatType.daily:
            next = DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
                reminder.scheduledTime.hour, reminder.scheduledTime.minute);
            break;
          case ns.RepeatType.weekly:
            next = reminder.scheduledTime.add(const Duration(days: 7));
            if (next.isBefore(tomorrow)) {
              next = next.add(const Duration(days: 7));
            }
            break;
          case ns.RepeatType.monthly:
            next = DateTime(
                tomorrow.year,
                tomorrow.month + 1,
                reminder.scheduledTime.day,
                reminder.scheduledTime.hour,
                reminder.scheduledTime.minute);
            break;
          case ns.RepeatType.none:
            break;
        }

        if (next != null) {
          await notificationService.updateScheduledTime(reminder.id!, next);
          // Also update push notification
          final push =
              Provider.of<ps.PushNotificationService>(context, listen: false);
          String repeatStr = 'none';
          switch (reminder.repeatType) {
            case ns.RepeatType.daily:
              repeatStr = 'daily';
              break;
            case ns.RepeatType.weekly:
              repeatStr = 'weekly';
              break;
            case ns.RepeatType.monthly:
              repeatStr = 'monthly';
              break;
            case ns.RepeatType.none:
              repeatStr = 'none';
              break;
          }
          await push.scheduleNotification(
            title: reminder.title,
            body: reminder.description,
            scheduledTime: next,
            type: _mapReminderTypeToPush(reminder.type),
            data: {
              'repeat': repeatStr,
              'hour': next.hour,
              'minute': next.minute,
              'reminder_id': reminder.id,
              'dismissed_today': true,
              'dismissed_date': today.toIso8601String(),
              'source': 'dismiss_today',
            },
          );
        }
      } else {
        // Non-repeating: just deactivate for today by updating to tomorrow
        final next = DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
            reminder.scheduledTime.hour, reminder.scheduledTime.minute);
        await notificationService.updateScheduledTime(reminder.id!, next);
        // Cancel any push notifications for today
        final push =
            Provider.of<ps.PushNotificationService>(context, listen: false);
        await push.cancelSchedulesForReminder(reminder.id!);
      }

      AuditLogService()
          .logAction('reminder_dismiss_today', data: {'id': reminder.id});
      if (!mounted) return;
      _loadReminders();
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  Future<void> _snoozeReminder(
      ns.NotificationItem reminder, Duration delay) async {
    try {
      if (reminder.id == null) return;
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      final db = DatabaseHelper.instance;
      final newTime = DateTime.now().add(delay);
      // Update schedule in local service
      final notificationService =
          Provider.of<ns.NotificationService>(context, listen: false);
      await notificationService.updateScheduledTime(reminder.id!, newTime);
      // Log action
      await db.insertReminderLog(
        reminderId: reminder.id!,
        userId: userId,
        action: 'snooze',
        actionDate: DateTime.now(),
        scheduledTime: newTime,
        metadata: 'minutes=${delay.inMinutes}',
      );
      // Push layer schedule one-off (no repeat)
      final push =
          Provider.of<ps.PushNotificationService>(context, listen: false);
      await push.scheduleNotification(
        title: reminder.title,
        body: reminder.description,
        scheduledTime: newTime,
        type: _mapReminderTypeToPush(reminder.type),
        data: {
          'repeat': 'none',
          'hour': newTime.hour,
          'minute': newTime.minute,
          'reminder_id': reminder.id,
          'source': 'snooze_10m',
        },
      );
      AuditLogService().logAction('reminder_snoozed',
          data: {'id': reminder.id, 'minutes': delay.inMinutes});
      if (!mounted) return;
      _loadReminders();
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  Future<void> _toggleReminder(ns.NotificationItem reminder) async {
    try {
      final notificationService =
          Provider.of<ns.NotificationService>(context, listen: false);
      final push =
          Provider.of<ps.PushNotificationService>(context, listen: false);
      if (reminder.id != null) {
        await notificationService.toggleNotification(reminder.id!);
        // Persist to DB if logged in
        final prefs = await PreferencesService.getInstance();
        final userId = prefs.getCurrentUserId();
        if (userId != null) {
          await WebDatabaseHelper.instance
              .updateReminderStatus(userId, reminder.id!, !reminder.isActive);
        }
        // Cancel or schedule based on new active state
        if (reminder.isActive) {
          // It was active, now will be inactive -> cancel schedules
          await push.cancelSchedulesForReminder(reminder.id!);
        } else {
          // It was inactive, now will be active -> schedule
          final dt = reminder.scheduledTime;
          String repeatStr = 'none';
          switch (reminder.repeatType) {
            case ns.RepeatType.daily:
              repeatStr = 'daily';
              break;
            case ns.RepeatType.weekly:
              repeatStr = 'weekly';
              break;
            case ns.RepeatType.monthly:
              repeatStr = 'monthly';
              break;
            case ns.RepeatType.none:
              repeatStr = 'none';
              break;
          }
          await push.scheduleNotification(
            title: reminder.title,
            body: reminder.description,
            scheduledTime: dt,
            type: _mapReminderTypeToPush(reminder.type),
            data: {
              'repeat': repeatStr,
              'hour': dt.hour,
              'minute': dt.minute,
              'reminder_id': reminder.id,
              'source': 'toggle_on',
            },
          );
        }
        AuditLogService().logAction('reminder_toggled', data: {
          'id': reminder.id,
          'active': !reminder.isActive,
        });
        if (!mounted) return;
        _loadReminders();
      }
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  Future<void> _deleteReminder(ns.NotificationItem reminder) async {
    try {
      final notificationService =
          Provider.of<ns.NotificationService>(context, listen: false);
      final push =
          Provider.of<ps.PushNotificationService>(context, listen: false);
      if (reminder.id != null) {
        await notificationService.removeNotification(reminder.id!);
        // Persist deletion if logged in
        final prefs = await PreferencesService.getInstance();
        final userId = prefs.getCurrentUserId();
        if (userId != null) {
          await WebDatabaseHelper.instance.deleteReminder(userId, reminder.id!);
        }
        // Cancel any scheduled notifications for this reminder
        await push.cancelSchedulesForReminder(reminder.id!);
        AuditLogService()
            .logAction('reminder_deleted', data: {'id': reminder.id});
        if (!mounted) return;
        _loadReminders();
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.getString('reminder_deleted'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  // Map local NotificationType to PushNotificationService.NotificationType
  ps.NotificationType _mapReminderTypeToPush(ns.NotificationType type) {
    switch (type) {
      case ns.NotificationType.medication:
        return ps.NotificationType.medication;
      case ns.NotificationType.appointment:
        return ps.NotificationType.appointment;
      case ns.NotificationType.test:
        return ps.NotificationType.test;
      case ns.NotificationType.reminder:
        return ps.NotificationType.reminder;
      case ns.NotificationType.general:
        return ps.NotificationType.general;
    }
  }

  Widget _buildReminderCard(ns.NotificationItem reminder) {
    final isOverdue =
        reminder.scheduledTime.isBefore(DateTime.now()) && reminder.isActive;
    final loc = Provider.of<LocalizationService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showReminderDetails(reminder),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOverdue
                ? Border.all(
                    color: Theme.of(context).colorScheme.error, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(reminder.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(reminder.type),
                  color: _getTypeColor(reminder.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isOverdue
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(reminder.scheduledTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.75),
                            fontWeight:
                                isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: DatabaseHelper.instance.getReminderStreak(
                              reminder.id ?? -1,
                              userId: PreferencesService().getCurrentUserId()),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            final data = snapshot.data!;
                            final current =
                                (data['current_streak'] as int? ?? 0);
                            final longest =
                                (data['longest_streak'] as int? ?? 0);
                            if (current <= 0) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                      '${loc.getString('current_streak_label')}: $current ${loc.getString('days_suffix')}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange)),
                                  if (longest > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                        '• ${loc.getString('longest_streak_label')}: $longest',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .getString('reminder_badge_overdue'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRoute: '/reminders'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: Provider.of<LocalizationService>(context, listen: false)
                .getString('menu'),
          ),
        ),
        title: Text(
          Provider.of<LocalizationService>(context)
              .getString('reminders_title'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReminders,
            icon: const Icon(Icons.refresh),
            tooltip: Provider.of<LocalizationService>(context, listen: false)
                .getString('refresh'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.7),
          tabs: [
            Tab(
              text: Provider.of<LocalizationService>(context)
                  .getString('reminder_tab_upcoming'),
              icon: Badge(
                label: Text(_upcomingReminders.length.toString()),
                child: const Icon(Icons.upcoming),
              ),
            ),
            Tab(
              text: Provider.of<LocalizationService>(context)
                  .getString('reminder_tab_overdue'),
              icon: Badge(
                label: Text(_overdueReminders.length.toString()),
                child: const Icon(Icons.warning),
              ),
            ),
            Tab(
              text: Provider.of<LocalizationService>(context)
                  .getString('reminder_tab_completed'),
              icon: Badge(
                label: Text(_completedReminders.length.toString()),
                child: const Icon(Icons.check_circle),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming
                _upcomingReminders.isEmpty
                    ? _buildEmptyState(
                        Provider.of<LocalizationService>(context)
                            .getString('reminder_empty_upcoming'),
                        Icons.schedule,
                      )
                    : ListView.builder(
                        itemCount: _upcomingReminders.length,
                        itemBuilder: (context, index) {
                          return _buildReminderCard(_upcomingReminders[index]);
                        },
                      ),

                // Overdue
                _overdueReminders.isEmpty
                    ? _buildEmptyState(
                        Provider.of<LocalizationService>(context)
                            .getString('reminder_empty_overdue'),
                        Icons.check_circle_outline,
                      )
                    : ListView.builder(
                        itemCount: _overdueReminders.length,
                        itemBuilder: (context, index) {
                          return _buildReminderCard(_overdueReminders[index]);
                        },
                      ),

                // Completed
                _completedReminders.isEmpty
                    ? _buildEmptyState(
                        Provider.of<LocalizationService>(context)
                            .getString('reminder_empty_completed'),
                        Icons.history,
                      )
                    : ListView.builder(
                        itemCount: _completedReminders.length,
                        itemBuilder: (context, index) {
                          return _buildReminderCard(_completedReminders[index]);
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddReminderScreen(),
            ),
          ).then((_) => _loadReminders());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
