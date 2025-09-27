import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../widgets/app_drawer.dart';
import '../services/localization_service.dart';
import 'add_reminder_screen.dart';
import '../services/audit_log_service.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({Key? key}) : super(key: key);

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItem> _allReminders = [];
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
      final notificationService = Provider.of<NotificationService>(context, listen: false);
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

  List<NotificationItem> get _upcomingReminders {
    final now = DateTime.now();
    return _allReminders
        .where((r) => r.isActive && r.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  List<NotificationItem> get _overdueReminders {
    final now = DateTime.now();
    return _allReminders
        .where((r) => r.isActive && r.scheduledTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  List<NotificationItem> get _completedReminders {
    return _allReminders
        .where((r) => !r.isActive)
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_medication');
      case NotificationType.test:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_test');
      case NotificationType.appointment:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_appointment');
      case NotificationType.reminder:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_general_reminder');
      case NotificationType.general:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_general');
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Icons.medication;
      case NotificationType.test:
        return Icons.science;
      case NotificationType.appointment:
        return Icons.event;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Colors.green;
      case NotificationType.test:
        return Colors.blue;
      case NotificationType.appointment:
        return Colors.orange;
      case NotificationType.reminder:
        return const Color(0xFFE53E3E);
      case NotificationType.general:
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

  void _showReminderDetails(NotificationItem reminder) {
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
                            color: _getTypeColor(reminder.type).withValues(alpha: 0.1),
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                Provider.of<LocalizationService>(context, listen: false).getString('reminder_time_label'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(reminder.scheduledTime),
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
                      Provider.of<LocalizationService>(context, listen: false).getString('reminder_description_heading'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reminder.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleReminder(reminder);
                            },
                            icon: Icon(reminder.isActive ? Icons.pause : Icons.play_arrow),
                            label: Text(reminder.isActive 
                              ? Provider.of<LocalizationService>(context, listen: false).getString('reminder_action_pause')
                              : Provider.of<LocalizationService>(context, listen: false).getString('reminder_action_activate')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
                            label: Text(Provider.of<LocalizationService>(context, listen: false).getString('delete')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _toggleReminder(NotificationItem reminder) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      if (reminder.id != null) {
        await notificationService.toggleNotification(reminder.id!);
        // Persist to DB if logged in
        final prefs = await PreferencesService.getInstance();
        final userId = prefs.getCurrentUserId();
        if (userId != null) {
          await WebDatabaseHelper.instance.updateReminderStatus(userId, reminder.id!, !reminder.isActive);
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
        SnackBar(content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  Future<void> _deleteReminder(NotificationItem reminder) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      if (reminder.id != null) {
        await notificationService.removeNotification(reminder.id!);
        // Persist deletion if logged in
        final prefs = await PreferencesService.getInstance();
        final userId = prefs.getCurrentUserId();
        if (userId != null) {
          await WebDatabaseHelper.instance.deleteReminder(userId, reminder.id!);
        }
        AuditLogService().logAction('reminder_deleted', data: {'id': reminder.id});
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
        SnackBar(content: Text('${loc.getString('error_prefix')}${e.toString()}')),
      );
    }
  }

  Widget _buildReminderCard(NotificationItem reminder) {
    final isOverdue = reminder.scheduledTime.isBefore(DateTime.now()) && reminder.isActive;
    
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
            border: isOverdue ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(reminder.type).withValues(alpha: 0.1),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.description,
                      style: TextStyle(
                        color: Colors.grey[600],
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
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(reminder.scheduledTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false).getString('reminder_badge_overdue'),
                    style: const TextStyle(
                      color: Colors.white,
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
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF0D1117) 
        : Colors.grey[50],
      drawer: const AppDrawer(currentRoute: '/reminders'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: Provider.of<LocalizationService>(context, listen: false).getString('menu'),
          ),
        ),
        title: Text(
          Provider.of<LocalizationService>(context).getString('reminders_title'),
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
          IconButton(
            onPressed: _loadReminders,
            icon: const Icon(Icons.refresh),
            tooltip: Provider.of<LocalizationService>(context, listen: false).getString('refresh'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: Provider.of<LocalizationService>(context).getString('reminder_tab_upcoming'),
              icon: Badge(
                label: Text(_upcomingReminders.length.toString()),
                child: const Icon(Icons.upcoming),
              ),
            ),
            Tab(
              text: Provider.of<LocalizationService>(context).getString('reminder_tab_overdue'),
              icon: Badge(
                label: Text(_overdueReminders.length.toString()),
                child: const Icon(Icons.warning),
              ),
            ),
            Tab(
              text: Provider.of<LocalizationService>(context).getString('reminder_tab_completed'),
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
                        Provider.of<LocalizationService>(context).getString('reminder_empty_upcoming'),
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
                        Provider.of<LocalizationService>(context).getString('reminder_empty_overdue'),
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
                        Provider.of<LocalizationService>(context).getString('reminder_empty_completed'),
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
        backgroundColor: const Color(0xFFE53E3E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}