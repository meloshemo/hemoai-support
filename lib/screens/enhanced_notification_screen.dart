import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/push_notification_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/audit_log_service.dart';

class EnhancedNotificationScreen extends StatefulWidget {
  const EnhancedNotificationScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedNotificationScreen> createState() => _EnhancedNotificationScreenState();
}

class _EnhancedNotificationScreenState extends State<EnhancedNotificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  TimeOfDay? _dailyMotivationTime;
  String _currentQuote = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
    _loadMotivationPrefs();
    _rotateQuote(initial: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    // Initialize push notification service if not already done
    final pushService = Provider.of<PushNotificationService>(context, listen: false);
    if (!pushService.isInitialized) {
      await pushService.initialize();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMotivationPrefs() async {
    final prefs = await PreferencesService.getInstance();
    final hour = prefs.getCustomSetting<int>('daily_motivation_hour');
    final minute = prefs.getCustomSetting<int>('daily_motivation_minute');
    if (hour != null && minute != null) {
      setState(() {
        _dailyMotivationTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  void _rotateQuote({bool initial = false}) {
    final loc = LocalizationService();
    final base = (loc.getString('motivational_custom_quote').isNotEmpty)
        ? loc.getString('motivational_custom_quote')
        : loc.getString('motivational_message_long');
    // For now, just pick base; if we had a list, cycle it. Keep deterministic unless user taps rotate.
    setState(() {
      _currentQuote = base;
    });
    if (!initial) {
      AuditLogService().logAction('motivation_rotated');
    }
  }

  Future<void> _pickDailyMotivationTime() async {
    final loc = LocalizationService();
    final prefs = await PreferencesService.getInstance();
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyMotivationTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dailyMotivationTime = picked);
      await prefs.saveCustomSettings('daily_motivation_hour', picked.hour);
      await prefs.saveCustomSettings('daily_motivation_minute', picked.minute);

      // Schedule via push service
      final push = Provider.of<PushNotificationService>(context, listen: false);
      await push.scheduleDailyMotivation(hour: picked.hour, minute: picked.minute, quote: _currentQuote);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.getString('daily_motivation_time')}: ${picked.format(context)}')),
      );
      AuditLogService().logAction('daily_motivation_scheduled', data: {
        'hour': picked.hour,
        'minute': picked.minute,
      });
    }
  }

  Widget _buildMotivationCard() {
    final loc = LocalizationService();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_emotions, color: Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.getString('motivational_rotating_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: loc.getString('refresh'),
                  onPressed: () => _rotateQuote(),
                  icon: const Icon(Icons.refresh, color: Color(0xFFE53E3E)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentQuote,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // Simple share via clipboard-like feedback
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.getString('quote_copied'))),
                    );
                    AuditLogService().logAction('motivation_shared');
                  },
                  icon: const Icon(Icons.share),
                  label: Text(loc.getString('share_quote')),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E), foregroundColor: Colors.white),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDailyMotivationTime,
                  icon: const Icon(Icons.alarm),
                  label: Text(_dailyMotivationTime == null
                      ? loc.getString('daily_motivation_time')
                      : '${loc.getString('daily_motivation_time')}: ${_dailyMotivationTime!.format(context)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return LocalizationService.translate('medication_reminder');
      case NotificationType.appointment:
        return LocalizationService.translate('appointment');
      case NotificationType.test:
        return LocalizationService.translate('test_analysis');
      case NotificationType.healthAlert:
        return LocalizationService.translate('health_alert');
      case NotificationType.reminder:
        return LocalizationService.translate('reminder');
      case NotificationType.system:
        return LocalizationService.translate('system');
      case NotificationType.general:
        return LocalizationService.translate('general');
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Icons.medication;
      case NotificationType.appointment:
        return Icons.event;
      case NotificationType.test:
        return Icons.science;
      case NotificationType.healthAlert:
        return Icons.health_and_safety;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Colors.green;
      case NotificationType.appointment:
        return Colors.blue;
      case NotificationType.test:
        return Colors.orange;
      case NotificationType.healthAlert:
        return Colors.red;
      case NotificationType.reminder:
        return const Color(0xFFE53E3E);
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.general:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return LocalizationService.translate('just_now');
    } else if (difference.inHours < 1) {
      return LocalizationService.translate('minutes_ago').replaceFirst('{count}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return LocalizationService.translate('hours_ago').replaceFirst('{count}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return LocalizationService.translate('days_ago').replaceFirst('{count}', difference.inDays.toString());
    } else {
      return LocalizationService().formatDate(dateTime);
    }
  }

  Widget _buildNotificationCard(NotificationMessage notification) {
    final typeColor = _getTypeColor(notification.type);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: notification.isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _showNotificationDetails(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: !notification.isRead 
                ? Border.all(color: typeColor, width: 2)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead 
                                  ? FontWeight.w600 
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeDisplayName(notification.type),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(notification.receivedAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationMessage notification) {
    // Mark as read when opened
    if (!notification.isRead) {
      Provider.of<PushNotificationService>(context, listen: false)
          .markAsRead(notification.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
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
                            color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(notification.type),
                            color: _getTypeColor(notification.type),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTypeDisplayName(notification.type),
                                style: TextStyle(
                                  color: _getTypeColor(notification.type),
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
                        color: Colors.grey[100],
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
                                LocalizationService.translate('received_time'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(notification.receivedAt),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      LocalizationService.translate('details'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          notification.body,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getTypeColor(notification.type),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(LocalizationService.translate('close')),
                      ),
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

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.translate('quick_actions'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: LocalizationService.translate('medication_reminder'),
                  subtitle: LocalizationService.translate('add_new_medication'),
                  icon: Icons.medication,
                  color: Colors.green,
                  onTap: () => _scheduleQuickReminder('medication'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: LocalizationService.translate('appointment'),
                  subtitle: LocalizationService.translate('doctor_appointment'),
                  icon: Icons.event,
                  color: Colors.blue,
                  onTap: () => _scheduleQuickReminder('appointment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: LocalizationService.translate('test_reminder'),
                  subtitle: LocalizationService.translate('analysis_time'),
                  icon: Icons.science,
                  color: Colors.orange,
                  onTap: () => _scheduleQuickReminder('test'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: LocalizationService.translate('general'),
                  subtitle: LocalizationService.translate('reminder'),
                  icon: Icons.alarm,
                  color: const Color(0xFFE53E3E),
                  onTap: () => Navigator.pushNamed(context, '/add_reminder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleQuickReminder(String type) {
    final now = DateTime.now();
    final pushService = Provider.of<PushNotificationService>(context, listen: false);

    switch (type) {
      case 'medication':
        pushService.scheduleMedicationReminder(
          medicationName: LocalizationService.translate('medication_reminder'),
          scheduleTime: now.add(const Duration(minutes: 1)),
        );
        break;
      case 'appointment':
        pushService.scheduleAppointmentReminder(
          doctorName: LocalizationService.translate('your_doctor'),
          appointmentTime: now.add(const Duration(minutes: 2)),
        );
        break;
      case 'test':
        pushService.scheduleTestReminder(
          testName: LocalizationService.translate('hemogram_test'),
          testTime: now.add(const Duration(minutes: 3)),
        );
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.translate('reminder_scheduled').replaceFirst('{type}', type)),
        backgroundColor: const Color(0xFFE53E3E),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PushNotificationService>(
      builder: (context, pushService, child) {
        final allNotifications = pushService.receivedNotifications;
        final unreadNotifications = allNotifications.where((n) => !n.isRead).toList();
        final readNotifications = allNotifications.where((n) => n.isRead).toList();
        final scheduledNotifications = pushService.scheduledNotifications;

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF0D1117) 
            : Colors.grey[50],
          drawer: const AppDrawer(currentRoute: '/notifications'),
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: LocalizationService.translate('menu'),
              ),
            ),
            title: Text(
              LocalizationService.translate('notifications'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF161B22) 
              : const Color(0xFFE53E3E),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (allNotifications.isNotEmpty)
                IconButton(
                  onPressed: () {
                    pushService.clearAllNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(LocalizationService.translate('all_notifications_cleared'))),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  tooltip: LocalizationService.translate('clear_all'),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  text: LocalizationService.translate('unread'),
                  icon: Badge(
                    label: Text(unreadNotifications.length.toString()),
                    child: const Icon(Icons.markunread),
                  ),
                ),
                Tab(
                  text: LocalizationService.translate('all'),
                  icon: Badge(
                    label: Text(allNotifications.length.toString()),
                    child: const Icon(Icons.notifications),
                  ),
                ),
                Tab(
                  text: LocalizationService.translate('scheduled'),
                  icon: Badge(
                    label: Text(scheduledNotifications.length.toString()),
                    child: const Icon(Icons.schedule),
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
                    // Unread Tab
                    unreadNotifications.isEmpty
                        ? Column(
                            children: [
                              _buildMotivationCard(),
                              _buildQuickActions(),
                              Expanded(
                                child: _buildEmptyState(
                                  LocalizationService.translate('no_unread_notifications'),
                                  Icons.mark_email_read,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildMotivationCard(),
                              _buildQuickActions(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: unreadNotifications.length,
                                  itemBuilder: (context, index) {
                                    return _buildNotificationCard(unreadNotifications[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                    
                    // All Tab
                    allNotifications.isEmpty
                        ? Column(
                            children: [
                              _buildMotivationCard(),
                              _buildQuickActions(),
                              Expanded(
                                child: _buildEmptyState(
                                  LocalizationService.translate('no_notifications_yet'),
                                  Icons.notifications_none,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: allNotifications.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildMotivationCard();
                              return _buildNotificationCard(allNotifications[index - 1]);
                            },
                          ),
                    
                    // Scheduled Tab
                    scheduledNotifications.isEmpty
                        ? _buildEmptyState(
                            LocalizationService.translate('no_scheduled_notifications'),
                            Icons.schedule_send,
                          )
                        : ListView.builder(
                            itemCount: scheduledNotifications.length,
                            itemBuilder: (context, index) {
                              final scheduled = scheduledNotifications[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getTypeColor(scheduled.type).withOpacity(0.1),
                                    child: Icon(
                                      _getTypeIcon(scheduled.type),
                                      color: _getTypeColor(scheduled.type),
                                    ),
                                  ),
                                  title: Text(scheduled.title),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(scheduled.body),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${LocalizationService.translate('scheduled_prefix')} ${LocalizationService().formatDate(scheduled.scheduledTime)} ${scheduled.scheduledTime.hour.toString().padLeft(2, '0')}:${scheduled.scheduledTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.cancel),
                                    onPressed: () {
                                      pushService.cancelNotification(scheduled.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(LocalizationService.translate('notification_cancelled'))),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
        );
      },
    );
  }
}