import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io' show File;
import '../widgets/app_drawer.dart';
import '../services/push_notification_service.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/daily_advice_service.dart';
import '../repositories/medication_repository.dart';
import '../repositories/water_repository.dart';

class EnhancedNotificationScreen extends StatefulWidget {
  const EnhancedNotificationScreen({super.key});

  @override
  State<EnhancedNotificationScreen> createState() =>
      _EnhancedNotificationScreenState();
}

class _EnhancedNotificationScreenState extends State<EnhancedNotificationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  TimeOfDay? _dailyMotivationTime;
  String _currentQuote = '';
  List<Map<String, dynamic>> _medications = const [];
  Map<String, bool> _notificationSettings = const {};
  int _waterGoal = 8;
  int _waterCount = 0;
  bool _lifestyleLoading = true;
  final Set<NotificationType> _activeFilters = <NotificationType>{};
  bool _sharing = false;
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Simplified: Wellness, Scheduled, Settings
    _initializeNotifications();
    _loadMotivationPrefs();
    _initializeQuotes();
    Future.microtask(_loadLifestyleData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Initialize push notification service if not already done
    final pushService =
        Provider.of<PushNotificationService>(context, listen: false);
    if (!pushService.isInitialized) {
      await pushService.initialize();
    }
    if (!mounted) return;
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

  Future<void> _loadLifestyleData() async {
    final medicationRepo =
        Provider.of<MedicationRepository>(context, listen: false);
    final waterRepo = Provider.of<WaterRepository>(context, listen: false);
    final prefs = await PreferencesService.getInstance();
    Map<String, bool> settings = prefs.getNotificationSettings();
    final waterGoal = prefs.getWaterDailyGoal();
    List<Map<String, dynamic>> meds = const [];
    int waterCount = 0;

    try {
      final userId = await prefs.getUserId();
      if (userId != null) {
        meds = await medicationRepo.getMedications(userId);
        waterCount = await waterRepo.getTodayWaterIntake(userId);
      }
    } catch (e) {
      debugPrint('Lifestyle data load error: $e');
    }

    if (!mounted) return;

    setState(() {
      _notificationSettings = _mergeSettings(settings);
      _waterGoal = waterGoal;
      _waterCount = waterCount;
      _medications = _normalizeMedicationData(meds);
      _lifestyleLoading = false;
    });
  }

  Map<String, bool> _mergeSettings(Map<String, bool> stored) {
    final defaults = <String, bool>{
      'medication_reminders': true,
      'test_reminders': true,
      'appointment_reminders': true,
      'critical_alerts': true,
      'nutrition_tips': false,
      'water_reminders': true,
      'daily_motivation': true,
    };
    for (final entry in stored.entries) {
      if (defaults.containsKey(entry.key)) {
        defaults[entry.key] = entry.value;
      }
    }
    return defaults;
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final prefs = await PreferencesService.getInstance();
    final updated = Map<String, bool>.from(_notificationSettings)
      ..[key] = value;
    setState(() {
      _notificationSettings = updated;
    });
    await prefs.saveNotificationSettings(updated);
  }

  List<Map<String, dynamic>> _normalizeMedicationData(
      List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return const [];
    final loc = LocalizationService();
    return raw.map((m) {
      return {
        'id': m['id'],
        'name': m['name'] ?? loc.getString('medication'),
        'dosage': m['dosage'] ?? loc.getString('default_dosage'),
        'frequency': m['frequency'] ?? loc.getString('default_frequency'),
        'time': m['time'] ?? '08:00',
        'taken_today': (m['taken_today'] is bool) ? m['taken_today'] : false,
        'total_days': (m['total_days'] is int) ? m['total_days'] : 30,
        'completed_days':
            (m['completed_days'] is int) ? m['completed_days'] : 0,
      };
    }).toList();
  }

  void _toggleTypeFilter(NotificationType type) {
    setState(() {
      if (_activeFilters.contains(type)) {
        _activeFilters.remove(type);
      } else {
        _activeFilters.add(type);
      }
    });
  }

  void _clearFilters() {
    setState(() => _activeFilters.clear());
  }

  List<NotificationMessage> _applyFilters(List<NotificationMessage> source) {
    if (_activeFilters.isEmpty) return source;
    return source.where((n) => _activeFilters.contains(n.type)).toList();
  }

  void _initializeQuotes() {
    final loc = LocalizationService();
    final svc = DailyAdviceService();
    final today = svc.getTodayQuoteText(loc);
    final all = svc.getAllQuotes(loc);
    setState(() {
      _currentQuote = today.isNotEmpty
          ? today
          : (all.isNotEmpty
              ? all.first
              : loc.getString('motivational_message_long'));
    });
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

  Color _getTypeColor(NotificationType type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case NotificationType.medication:
        return Colors.green; // Semantic color - success
      case NotificationType.appointment:
        return colorScheme.primary; // Use theme primary instead of blue
      case NotificationType.test:
        return Colors.orange; // Semantic color - warning
      case NotificationType.healthAlert:
        return colorScheme.error; // Use theme error instead of red
      case NotificationType.reminder:
        return colorScheme.primary; // Use theme primary
      case NotificationType.system:
        return colorScheme.outline; // Use theme outline instead of grey
      case NotificationType.general:
        return colorScheme.secondary; // Use theme secondary instead of purple
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return LocalizationService.translate('just_now');
    } else if (difference.inHours < 1) {
      return LocalizationService.translate('minutes_ago')
          .replaceFirst('{count}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return LocalizationService.translate('hours_ago')
          .replaceFirst('{count}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return LocalizationService.translate('days_ago')
          .replaceFirst('{count}', difference.inDays.toString());
    } else {
      return LocalizationService().formatDate(dateTime);
    }
  }

  Widget _buildNotificationCard(NotificationMessage notification) {
    final typeColor = _getTypeColor(notification.type, context);
    final loc = LocalizationService();
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final svc = Provider.of<PushNotificationService>(
                                  context,
                                  listen: false);
                              final messenger = ScaffoldMessenger.of(context);
                              await svc.snoozeReceived(
                                  message: notification,
                                  delay: const Duration(minutes: 10));
                              messenger.showSnackBar(
                                SnackBar(
                                    content:
                                        Text(loc.getString('snoozed_for_10'))),
                              );
                            },
                            icon: const Icon(Icons.snooze, size: 18),
                            label: Text(loc.getString('snooze_10m')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final svc = Provider.of<PushNotificationService>(
                                  context,
                                  listen: false);
                              final messenger = ScaffoldMessenger.of(context);
                              await svc.snoozeReceived(
                                  message: notification,
                                  delay: const Duration(minutes: 30));
                              messenger.showSnackBar(
                                SnackBar(
                                    content:
                                        Text(loc.getString('snoozed_for_30'))),
                              );
                            },
                            icon: const Icon(Icons.snooze, size: 18),
                            label: Text(loc.getString('snooze_30m')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final svc = Provider.of<PushNotificationService>(
                                  context,
                                  listen: false);
                              final messenger = ScaffoldMessenger.of(context);
                              await svc.dismissForToday(received: notification);
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text(
                                        loc.getString('dismissed_for_today'))),
                              );
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(loc.getString('snooze_dismiss_today')),
                          ),
                        ),
                      ],
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
                            color: _getTypeColor(notification.type, context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(notification.type),
                            color: _getTypeColor(notification.type, context),
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
                                  color:
                                      _getTypeColor(notification.type, context),
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
                              Expanded(
                                child: Text(
                                  LocalizationService.translate('received_time'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
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
                          backgroundColor:
                              _getTypeColor(notification.type, context),
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
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
    final loc = LocalizationService();
    final scheme = Theme.of(context).colorScheme;
    final quickCards = [
      {
        'title': loc.getString('medication_reminder'),
        'subtitle': loc.getString('add_new_medication'),
        'icon': Icons.medical_services_outlined,
        'color': scheme.primary,
        // Route to add reminder form to let users set details
        'onTap': () => Navigator.pushNamed(context, '/add_reminder'),
      },
      {
        'title': loc.getString('appointment'),
        'subtitle': loc.getString('doctor_appointment'),
        'icon': Icons.event_available,
        'color': scheme.tertiary,
        // Route to add reminder form to let users set details
        'onTap': () => Navigator.pushNamed(context, '/add_reminder'),
      },
      {
        'title': loc.getString('test_reminder'),
        'subtitle': loc.getString('analysis_time'),
        'icon': Icons.science_outlined,
        'color': scheme.secondary,
        // Route to add reminder form to let users set details
        'onTap': () => Navigator.pushNamed(context, '/add_reminder'),
      },
      {
        'title': loc.getString('general'),
        'subtitle': loc.getString('reminder'),
        'icon': Icons.alarm_add,
        'color': scheme.error,
        'onTap': () => Navigator.pushNamed(context, '/add_reminder'),
      },
    ];

    return SizedBox(
      height: 168,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: quickCards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final card = quickCards[index];
          return _buildActionCard(
            title: card['title'] as String,
            subtitle: card['subtitle'] as String,
            icon: card['icon'] as IconData,
            color: card['color'] as Color,
            onTap: card['onTap'] as VoidCallback,
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = color.withValues(alpha: isDark ? 0.28 : 0.12);
    final accent = color.withValues(alpha: isDark ? 0.4 : 0.2);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.78);
    final iconBackground = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.82);
    final iconColor = isDark ? Colors.white : color.withValues(alpha: 0.9);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [base, accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(List<NotificationMessage> allItems) {
    final loc = LocalizationService();
    final typesInData = allItems.map((n) => n.type).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (typesInData.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0x331F2937)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                loc.getString('filter_by'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _activeFilters.isEmpty ? null : _clearFilters,
                child: Text(loc.getString('clear_filters')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: typesInData.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final selected = _activeFilters.isEmpty;
                  return FilterChip(
                    label: Text(loc.getString('filter_all')),
                    selected: selected,
                    onSelected: (_) => _clearFilters(),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35),
                    ),
                  );
                }
                final type = typesInData[index - 1];
                final selected = _activeFilters.contains(type);
                final color = _getTypeColor(type, context);
                return FilterChip(
                  label: Text(_getTypeDisplayName(type)),
                  selected: selected,
                  onSelected: (_) => _toggleTypeFilter(type),
                  selectedColor: color.withValues(alpha: 0.18),
                  checkmarkColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.35)),
                  labelStyle: TextStyle(
                    color: selected
                        ? color
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  avatar: Icon(
                    _getTypeIcon(type),
                    color: selected ? color : color.withValues(alpha: 0.9),
                    size: 18,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow({
    required List<NotificationMessage> allNotifications,
    required List<ScheduledNotification> scheduled,
    required int unreadCount,
  }) {
    if (allNotifications.isEmpty && scheduled.isEmpty) {
      return const SizedBox.shrink();
    }
    final loc = LocalizationService();
    final scheme = Theme.of(context).colorScheme;
    final completionGradient = [
      scheme.primary.withValues(alpha: 0.85),
      scheme.primary.withValues(alpha: 0.65),
    ];
    final medicationGradient = [
      scheme.secondary.withValues(alpha: 0.85),
      scheme.secondary.withValues(alpha: 0.65),
    ];
    final appointmentGradient = [
      scheme.tertiary.withValues(alpha: 0.85),
      scheme.tertiary.withValues(alpha: 0.6),
    ];
    final todayGradient = [
      scheme.error.withValues(alpha: 0.85),
      scheme.error.withValues(alpha: 0.6),
    ];
    final total = allNotifications.length.toDouble().clamp(1, double.infinity);
    final responded = total - unreadCount;

    final medicationCount = allNotifications
        .where((n) => n.type == NotificationType.medication)
        .length;
    final appointmentCount = allNotifications
        .where((n) => n.type == NotificationType.appointment)
        .length;
    final upcomingToday = scheduled.where((n) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final schedDay = DateTime(
          n.scheduledTime.year, n.scheduledTime.month, n.scheduledTime.day);
      return schedDay == today;
    }).length;

    final completionRate = (responded / total * 100).clamp(0, 100).round();
    final medicationRatio =
        (medicationCount / total * 100).clamp(0, 100).round();
    final appointmentRatio =
        (appointmentCount / total * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.getString('insights_title'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.task_alt,
                  gradient: completionGradient,
                  title: loc.getString('insight_completion'),
                  value: '$completionRate%',
                  subtitle: loc.getString('insight_completion_subtitle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.medication_outlined,
                  gradient: medicationGradient,
                  title: loc.getString('insight_medication_focus'),
                  value: '$medicationRatio%',
                  subtitle: loc.getString('insight_medication_subtitle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.event_available,
                  gradient: appointmentGradient,
                  title: loc.getString('insight_appointment_focus'),
                  value: '$appointmentRatio%',
                  subtitle: loc.getString('insight_appointment_subtitle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.schedule,
                  gradient: todayGradient,
                  title: loc.getString('insight_today'),
                  value: '$upcomingToday',
                  subtitle: loc.getString('insight_today_subtitle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(int unread, int total, int scheduled) {
    final loc = LocalizationService();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = scheme.primary.withValues(alpha: isDark ? 0.78 : 0.92);
    final end = scheme.primaryContainer.withValues(alpha: isDark ? 0.6 : 0.85);
    final onStart = scheme.onPrimary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: start.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.getString('notification_dashboard_title'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.getString('notification_dashboard_subtitle'),
            style: TextStyle(
              color: onStart.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  icon: Icons.mark_email_unread,
                  label: loc.getString('unread'),
                  value: unread.toString(),
                  colors: [
                    scheme.onPrimary.withValues(alpha: 0.18),
                    scheme.onPrimary.withValues(alpha: 0.05),
                  ],
                  foreground: onStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.all_inclusive,
                  label: loc.getString('all'),
                  value: total.toString(),
                  colors: [
                    scheme.onPrimary.withValues(alpha: 0.12),
                    scheme.onPrimary.withValues(alpha: 0.04),
                  ],
                  foreground: onStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.schedule,
                  label: loc.getString('scheduled'),
                  value: scheduled.toString(),
                  colors: [
                    scheme.onPrimary.withValues(alpha: 0.12),
                    scheme.onPrimary.withValues(alpha: 0.04),
                  ],
                  foreground: onStart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> colors,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: foreground, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationPanel() {
    final loc = LocalizationService();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_lifestyleLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final cardColor = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);
    final borderColor = scheme.outline.withValues(alpha: 0.2);
    final titleColor = theme.textTheme.titleMedium?.color ?? Colors.black87;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.medical_information,
                    color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.getString('medication_overview'),
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/reminders'),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(loc.getString('manage')),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_medications.isEmpty)
            _buildMedicationEmptyState(loc, scheme, isDark)
          else ...[
            ..._medications
                .take(3)
                .map((med) => _buildMedicationTile(med, scheme, isDark, loc)),
            if (_medications.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.getString('view_more_medications'),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/reminders'),
            icon: const Icon(Icons.add),
            label: Text(loc.getString('add_new_medication')),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationEmptyState(
    LocalizationService loc,
    ColorScheme scheme,
    bool isDark,
  ) {
    final textColor =
        isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.65);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_note, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.getString('no_medication_data'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          loc.getString('add_medication_hint'),
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationTile(
    Map<String, dynamic> med,
    ColorScheme scheme,
    bool isDark,
    LocalizationService loc,
  ) {
    final surfaceColor = isDark
        ? scheme.surface.withValues(alpha: 0.6)
        : scheme.surface.withValues(alpha: 0.9);
    final borderColor = scheme.outline.withValues(alpha: 0.12);
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final total =
        (med['total_days'] is num) ? (med['total_days'] as num).toDouble() : 30;
    final completed = (med['completed_days'] is num)
        ? (med['completed_days'] as num).toDouble()
        : 0;
    final percent = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final takenToday = med['taken_today'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  med['name']?.toString() ?? loc.getString('medication'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Chip(
                backgroundColor: takenToday
                    ? scheme.primary.withValues(alpha: 0.16)
                    : scheme.surfaceContainerHighest,
                label: Text(
                  takenToday
                      ? loc.getString('taken')
                      : loc.getString('pending'),
                  style: TextStyle(
                    color: takenToday ? scheme.primary : secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${med['dosage'] ?? ''} • ${med['frequency'] ?? ''} • ${med['time'] ?? '08:00'}',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${completed.toInt()} / ${total.toInt()} ${loc.getString('days')}',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    if (_lifestyleLoading) return const SizedBox.shrink();
    final loc = LocalizationService();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final progress =
        _waterGoal == 0 ? 0.0 : (_waterCount / _waterGoal).clamp(0.0, 1.0);
    final cardColor = isDark
        ? scheme.secondaryContainer.withValues(alpha: 0.55)
        : scheme.secondaryContainer.withValues(alpha: 0.9);
    final textColor = theme.textTheme.titleMedium?.color ?? Colors.black87;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.secondary),
                  backgroundColor:
                      scheme.onSecondaryContainer.withValues(alpha: 0.15),
                ),
                Center(
                  child: Text(
                    '${(_waterCount).clamp(0, _waterGoal)}/$_waterGoal',
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.getString('hydration_progress'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc
                      .getString('hydration_goal_label')
                      .replaceFirst('{goal}', _waterGoal.toString()),
                  style: TextStyle(
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/water'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.secondary,
                    side: BorderSide(
                        color: scheme.secondary.withValues(alpha: 0.4)),
                  ),
                  icon: const Icon(Icons.water_drop_outlined, size: 18),
                  label: Text(loc.getString('log_water')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final loc = LocalizationService();
    if (_lifestyleLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = [
      _NotificationSetting(
        keyName: 'medication_reminders',
        icon: Icons.medication_outlined,
        color: const Color(0xFF34D399),
        title: loc.getString('medication_reminder'),
        subtitle: loc.getString('setting_medication_desc'),
      ),
      _NotificationSetting(
        keyName: 'test_reminders',
        icon: Icons.science_outlined,
        color: const Color(0xFFFBBF24),
        title: loc.getString('test_reminder'),
        subtitle: loc.getString('setting_test_desc'),
      ),
      _NotificationSetting(
        keyName: 'appointment_reminders',
        icon: Icons.event_available,
        color: const Color(0xFF60A5FA),
        title: loc.getString('appointment'),
        subtitle: loc.getString('setting_appointment_desc'),
      ),
      _NotificationSetting(
        keyName: 'critical_alerts',
        icon: Icons.health_and_safety,
        color: const Color(0xFFE11D48),
        title: loc.getString('health_alert'),
        subtitle: loc.getString('setting_critical_desc'),
      ),
      _NotificationSetting(
        keyName: 'nutrition_tips',
        icon: Icons.restaurant_outlined,
        color: const Color(0xFFEC4899),
        title: loc.getString('diet'),
        subtitle: loc.getString('setting_nutrition_desc'),
      ),
      _NotificationSetting(
        keyName: 'water_reminders',
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF38BDF8),
        title: loc.getString('water_reminders_label'),
        subtitle: loc.getString('setting_water_desc'),
      ),
      _NotificationSetting(
        keyName: 'daily_motivation',
        icon: Icons.sentiment_satisfied_alt,
        color: const Color(0xFFA855F7),
        title: loc.getString('motivational_message'),
        subtitle: loc.getString('setting_motivation_desc'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 16),
        _buildSettingsHeader(loc),
        const SizedBox(height: 12),
        ...items.map((item) => _buildSettingTile(
            item, _notificationSettings[item.keyName] ?? false)),
      ],
    );
  }

  Widget _buildSettingsHeader(LocalizationService loc) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.tune, color: cs.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.getString('notification_settings_header'),
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.getString('notification_settings_description'),
            style: TextStyle(
              color: cs.onPrimary.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(_NotificationSetting item, bool value) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: (enabled) =>
            _updateNotificationSetting(item.keyName, enabled),
        activeTrackColor: item.color,
        activeThumbColor: item.color,
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationFeed({
    required List<NotificationMessage> items,
    required List<NotificationMessage> baseItems,
    required List<ScheduledNotification> scheduled,
    required String emptyMessage,
    required IconData emptyIcon,
    required int unreadCount,
    required int totalCount,
    required int scheduledCount,
    bool includeLifestyle = true,
    bool enableFilters = true,
  }) {
    final filteredItems = enableFilters ? _applyFilters(items) : items;

    final children = <Widget>[
      _buildStatusHeader(unreadCount, totalCount, scheduledCount),
      _buildQuickActions(),
      _buildInsightsRow(
        allNotifications: baseItems,
        scheduled: scheduled,
        unreadCount: unreadCount,
      ),
    ];

    if (enableFilters) {
      children.add(_buildFilterBar(baseItems));
    }

    if (includeLifestyle) {
      children.add(_buildMedicationPanel());
      children.add(_buildHydrationCard());
    }

    if (filteredItems.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _buildEmptyState(emptyMessage, emptyIcon),
        ),
      );
    } else {
      children.addAll(filteredItems.map(_buildNotificationCard));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: children,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = LocalizationService();
    return Consumer<PushNotificationService>(
      builder: (context, pushService, child) {
        final allNotifications = pushService.receivedNotifications;
        final unreadNotifications =
            allNotifications.where((n) => !n.isRead).toList();
        final scheduledNotifications = pushService.scheduledNotifications;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
          drawer: const AppDrawer(currentRoute: '/notifications'),
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: loc.getString('menu'),
              ),
            ),
            title: Text(
              loc.getString('notifications'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1F2937), Color(0xFF0F172A)]
                      : const [Color(0xFFE53E3E), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              if (allNotifications.isNotEmpty)
                IconButton(
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    pushService.clearAllNotifications();
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(LocalizationService.translate(
                              'all_notifications_cleared'))),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  tooltip: LocalizationService.translate('clear_all'),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.white, width: 3),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  text: loc.getString('wellness'),
                  icon: const Icon(Icons.favorite),
                ),
                Tab(
                  text: loc.getString('scheduled'),
                  icon: Badge(
                    label: Text(scheduledNotifications.length.toString()),
                    isLabelVisible: scheduledNotifications.isNotEmpty,
                    child: const Icon(Icons.schedule),
                  ),
                ),
                Tab(
                  text: loc.getString('settings'),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Wellness Tab - Focus on lifestyle tracking
                    _buildWellnessTab(),
                    // Scheduled Tab
                    _buildScheduledTab(
                      scheduledNotifications,
                      allNotifications,
                      unreadNotifications.length,
                    ),
                    // Settings Tab
                    _buildSettingsTab(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildWellnessTab() {
    final loc = LocalizationService();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_lifestyleLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadLifestyleData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Motivation Card
            _buildMotivationCard(loc, isDark),
            const SizedBox(height: 16),
            
            // Water Tracking Card
            _buildWaterTrackingCard(loc, isDark),
            const SizedBox(height: 16),
            
            // Medications Section
            Text(
              loc.getString('daily_medication_tracking'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            if (_medications.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.getString('no_medications'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._medications.map((med) => _buildMedicationCard(med, loc, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard(LocalizationService loc, bool isDark) {
    final theme = Theme.of(context);
    final capture = RepaintBoundary(
      key: _shareKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.getString('daily_motivation'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuote.isNotEmpty ? _currentQuote : loc.getString('motivational_message_long'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
            ),
            if (_dailyMotivationTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${loc.getString('daily_motivation_time')}: ${_dailyMotivationTime!.format(context)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container
                (
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    loc.getString('app_name'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        capture,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _shareMotivationImage,
                icon: const Icon(Icons.share),
                label: Text(loc.getString('share_quote')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                  disabledForegroundColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyQuote,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(loc.getString('copy')),
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadMotivationPngWeb,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(loc.getString('save')),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWaterTrackingCard(LocalizationService loc, bool isDark) {
    final progress = _waterGoal > 0 ? (_waterCount / _waterGoal).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.getString('daily_water_tracking'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$_waterCount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ $_waterGoal',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _waterCount > 0
                    ? () async {
                        final waterRepo = Provider.of<WaterRepository>(context, listen: false);
                        final prefs = await PreferencesService.getInstance();
                        final userId = await prefs.getUserId();
                        if (!mounted) return;
                        if (userId != null) {
                          await waterRepo.decrementWaterIntake(userId);
                          if (!mounted) return;
                          _loadLifestyleData();
                        }
                      }
                    : null,
                icon: const Icon(Icons.remove, size: 16),
                label: Text(loc.getString('water_decrease')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _waterCount < 12
                    ? () async {
                        final waterRepo = Provider.of<WaterRepository>(context, listen: false);
                        final prefs = await PreferencesService.getInstance();
                        final userId = await prefs.getUserId();
                        if (!mounted) return;
                        if (userId != null) {
                          await waterRepo.incrementWaterIntake(userId);
                          if (!mounted) return;
                          _loadLifestyleData();
                        }
                      }
                    : null,
                icon: const Icon(Icons.add, size: 16),
                label: Text(loc.getString('water_increase')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          if (_waterCount >= _waterGoal) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.getString('water_goal_completed_inline'),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication, LocalizationService loc, bool isDark) {
    final theme = Theme.of(context);
    final takenToday = medication['taken_today'] as bool? ?? false;
    final completedDays = medication['completed_days'] as int? ?? 0;
    final totalDays = medication['total_days'] as int? ?? 30;
    final progress = totalDays > 0 ? (completedDays / totalDays).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: takenToday ? Colors.green : theme.colorScheme.primary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: takenToday
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  takenToday ? Icons.check_circle : Icons.medication,
                  color: takenToday ? Colors.green : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name']?.toString() ?? loc.getString('medication'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${medication['dosage'] ?? loc.getString('default_dosage')} • ${medication['frequency'] ?? loc.getString('default_frequency')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${loc.getString('time_label')}: ${medication['time'] ?? '08:00'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: takenToday,
                onChanged: (value) {
                  setState(() {
                    medication['taken_today'] = value;
                    if (value && completedDays < totalDays) {
                      medication['completed_days'] = completedDays + 1;
                    }
                  });
                },
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedDays / $totalDays ${loc.getString('days_suffix')}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTab(
    List<ScheduledNotification> scheduled,
    List<NotificationMessage> allNotifications,
    int unreadCount,
  ) {
    final loc = LocalizationService();
    final totalCount = allNotifications.length;
    if (scheduled.isEmpty) {
      return _buildNotificationFeed(
        items: const [],
        baseItems: allNotifications,
        scheduled: scheduled,
        emptyMessage: loc.getString('no_scheduled_notifications'),
        emptyIcon: Icons.schedule_send,
        unreadCount: unreadCount,
        totalCount: totalCount,
        scheduledCount: 0,
        includeLifestyle: false,
        enableFilters: true,
      );
    }

    final children = <Widget>[
      _buildStatusHeader(unreadCount, totalCount, scheduled.length),
      _buildQuickActions(),
      _buildInsightsRow(
        allNotifications: allNotifications,
        scheduled: scheduled,
        unreadCount: unreadCount,
      ),
      ...scheduled.map(_buildScheduledCard),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: children,
    );
  }

  Widget _buildScheduledCard(ScheduledNotification scheduled) {
    final color = _getTypeColor(scheduled.type, context);
    final loc = LocalizationService();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161B22)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getTypeIcon(scheduled.type), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scheduled.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationService()
                          .formatTime(scheduled.scheduledTime),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  scheduled.body,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${loc.getString('scheduled_prefix')} ${LocalizationService().formatDate(scheduled.scheduledTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _scheduledActionButton(
                      icon: Icons.snooze,
                      label: loc.getString('snooze_10m'),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Provider.of<PushNotificationService>(context,
                                listen: false)
                            .snoozeScheduled(
                                scheduled: scheduled,
                                delay: const Duration(minutes: 10));
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(loc.getString('snoozed_for_10'))),
                        );
                      },
                    ),
                    _scheduledActionButton(
                      icon: Icons.snooze_outlined,
                      label: loc.getString('snooze_30m'),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Provider.of<PushNotificationService>(context,
                                listen: false)
                            .snoozeScheduled(
                                scheduled: scheduled,
                                delay: const Duration(minutes: 30));
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(loc.getString('snoozed_for_30'))),
                        );
                      },
                    ),
                    _scheduledActionButton(
                      icon: Icons.close,
                      label: loc.getString('snooze_dismiss_today'),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Provider.of<PushNotificationService>(context,
                                listen: false)
                            .dismissForToday(scheduled: scheduled);
                        messenger.showSnackBar(
                          SnackBar(
                              content:
                                  Text(loc.getString('dismissed_for_today'))),
                        );
                      },
                    ),
                    _scheduledActionButton(
                      icon: Icons.cancel_outlined,
                      label: loc.getString('cancel'),
                      onTap: () async {
                        Provider.of<PushNotificationService>(context,
                                listen: false)
                            .cancelNotification(scheduled.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  loc.getString('notification_cancelled'))),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduledActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Future<void> _shareMotivationImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final loc = LocalizationService();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final quote = _currentQuote.isNotEmpty
          ? _currentQuote
          : loc.getString('motivational_message_long');
      if (kIsWeb) {
        // Web share: fallback to plain text share
        Share.share('"$quote"');
      } else {
        final bytes = await _captureMotivationPng();
        if (bytes == null) {
          messenger.showSnackBar(
            SnackBar(content: Text(loc.getString('share_quote'))),
          );
        } else {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/hemoai_motivation.png');
          await file.writeAsBytes(bytes, flush: true);
          await Share.shareXFiles(
            [XFile(file.path)],
            text: loc.getString('share_quote'),
          );
        }
      }
    } catch (e) {
      debugPrint('Share motivation error: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(loc.getString('share_quote'))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List?> _captureMotivationPng() async {
    try {
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('capture error: $e');
      return null;
    }
  }

  Future<void> _copyQuote() async {
    final loc = LocalizationService();
    final quote = _currentQuote.isNotEmpty
        ? _currentQuote
        : loc.getString('motivational_message_long');
    await Clipboard.setData(ClipboardData(text: '"$quote"'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.getString('copied'))));
  }

  Future<void> _downloadMotivationPngWeb() async {
    try {
      final bytes = await _captureMotivationPng();
      if (bytes == null) return;
      await FileSaver.instance.saveFile(
        name: 'hemoai_motivation.png',
        bytes: bytes,
        mimeType: MimeType.png,
      );
    } catch (e) {
      debugPrint('download error: $e');
    }
  }
}

class _NotificationSetting {
  final String keyName;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _NotificationSetting({
    required this.keyName,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
