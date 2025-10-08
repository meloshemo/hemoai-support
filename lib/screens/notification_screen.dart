import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart' as inapp;
import 'package:flutter/services.dart';
import '../services/push_notification_service.dart' as push show PushNotificationService;
import '../services/analytics_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final WebDatabaseHelper _databaseHelper = WebDatabaseHelper.instance;
  final PreferencesService _preferencesService = PreferencesService();
  TimeOfDay? _dailyMotivationTime;
  
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> medications = [];
  bool isLoading = true;
  
  // Map backend notification types to icons/colors for UI
  IconData _iconForType(String? type) {
    switch (type) {
      case 'motivational':
        return Icons.favorite;
      case 'personalized_diet':
        return Icons.restaurant_menu;
      case 'test_reminder':
        return Icons.bloodtype;
      case 'water_achievement':
        return Icons.water_drop;
      case 'medication_added':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'motivational':
        return Colors.pink;
      case 'personalized_diet':
        return Colors.green;
      case 'test_reminder':
        return Colors.red;
      case 'water_achievement':
        return const Color(0xFF1E88E5);
      case 'medication_added':
        return const Color(0xFFE53E3E);
      default:
        return const Color(0xFFE53E3E);
    }
  }

  // Normalize DB notifications to UI-friendly shape
  List<Map<String, dynamic>> _normalizeNotifications(List<Map<String, dynamic>> raw, LocalizationService loc) {
    return raw.map((n) {
      final createdAt = (n['created_at'] ?? '') as String; 
      String date = '';
      String time = '';
      if (createdAt.isNotEmpty) {
        // Expecting ISO8601; split to date/time if possible
        final parts = createdAt.split('T');
        if (parts.isNotEmpty) {
          date = parts[0].replaceAll('-', '.');
        }
        if (parts.length > 1) {
          time = parts[1].substring(0, 5); // HH:mm
        }
      }

      final type = n['type'] as String?;
      final id = n['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final isRead = (n['isRead'] is bool)
          ? (n['isRead'] as bool)
          : ((n['is_read'] is bool) ? (n['is_read'] as bool) : false);
    final title = (n['title'] as String?) ?? loc.getString('notifications');
    final subtitle = (n['subtitle'] as String?) ?? loc.getString('no_subtitle');
    // Prefer description; fallback to message
    final description = (n['description'] as String?) ?? (n['message'] as String?) ?? loc.getString('no_description');

      return {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'type': type ?? 'general',
        'priority': (n['priority'] as String?) ?? 'medium',
        'icon': _iconForType(type),
        'color': _colorForType(type),
        'isRead': isRead,
        'date': date,
        'time': time,
      };
    }).toList();
  }

  // Normalize DB medications to UI-friendly shape
  List<Map<String, dynamic>> _normalizeMedications(List<Map<String, dynamic>> raw) {
    return raw.map((m) {
      return { 
  'name': m['name'] ?? Provider.of<LocalizationService>(context, listen: false).getString('medication'),
  'dosage': m['dosage'] ?? Provider.of<LocalizationService>(context, listen: false).getString('default_dosage'),
  'frequency': m['frequency'] ?? Provider.of<LocalizationService>(context, listen: false).getString('default_frequency'),
  'time': m['time'] ?? Provider.of<LocalizationService>(context, listen: false).getString('default_time'),
        'taken_today': (m['taken_today'] is bool) ? m['taken_today'] : false,
        'total_days': (m['total_days'] is int) ? m['total_days'] : 30,
        'completed_days': (m['completed_days'] is int) ? m['completed_days'] : 0,
      };
    }).toList();
  }
  
  // Localized sample notifications (fallback if DB empty / user not logged in)
  List<Map<String, dynamic>> _buildSampleNotifications(LocalizationService loc) {
    final now = DateTime.now();
    final dateLabel = '${now.day}.${now.month}.${now.year}';
    return [
  {
        'id': '1',
  'title': '🌟 ${loc.getString('motivational_message')}',
    'subtitle': loc.getString('take_care_today'),
    'description': (loc.getString('motivational_custom_quote').isNotEmpty)
    ? loc.getString('motivational_custom_quote')
    : loc.getString('motivational_message_long'),
        'time': '08:00',
        'date': dateLabel,
        'type': 'motivational',
        'priority': 'medium',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'isRead': false,
      },
      {
        'id': '2',
  'title': '🥗 ${loc.getString('personal_diet_suggestion')}',
        'subtitle': loc.getString('hemoglobin_menu_subtitle'),
        'description': loc.getString('personal_diet_plan_example'),
        'time': '07:30',
        'date': dateLabel,
        'type': 'personalized_diet',
        'priority': 'high',
        'icon': Icons.restaurant_menu,
        'color': Colors.green,
        'isRead': false,
      },
      {
        'id': '3',
  'title': '🩸 ${loc.getString('test_reminder_title')}',
        'subtitle': loc.getString('monthly_check_subtitle'),
        'description': loc.getString('test_reminder_description'),
        'time': '09:00',
        'date': dateLabel,
        'type': 'test_reminder',
        'priority': 'high',
        'icon': Icons.bloodtype,
        'color': Colors.red,
        'isRead': false,
      },
    ];
  }

  // Reminder settings
  final Map<String, bool> reminderSettings = {
    'test_reminders': true,
    'critical_alerts': true,
    'medication_reminders': true,
    'nutrition_tips': true,
    'personalized_diet': true,
    'motivational_messages': true,
    'health_tips': true,
    'smart_meals': true,
    'stress_management': true,
    'weekly_reports': true,
    'appointment_reminders': true,
    'water_reminders': true,
    'exercise_reminders': false,
  };

  // Water intake tracking
  int waterCount = 0;
  final int waterGoal = 8;

  // Sample medications (neutral English fallback)
  final List<Map<String, dynamic>> exampleMedications = [
    {
      'name': 'Iron Supplement',
      'dosage': '1 tablet',
      'frequency': 'Once daily',
      'time': '20:00',
      'taken_today': true,
      'total_days': 30,
      'completed_days': 15,
    },
    {
      'name': 'Vitamin B12',
      'dosage': '1 capsule',
      'frequency': 'Twice weekly',
      'time': '09:00',
      'taken_today': false,
      'total_days': 60,
      'completed_days': 8,
    },
    {
      'name': 'Folic Acid',
      'dosage': '1 tablet',
      'frequency': 'Once daily',
      'time': '08:00',
      'taken_today': true,
      'total_days': 30,
      'completed_days': 22,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializePrefsAndData();
  }

  Future<void> _initializePrefsAndData() async {
    // Ensure SharedPreferences is initialized and load saved daily motivation time
    await PreferencesService.getInstance();
    final savedHour = _preferencesService.getCustomSetting<int>('daily_motivation_hour');
    final savedMinute = _preferencesService.getCustomSetting<int>('daily_motivation_minute');
    if (mounted && savedHour != null && savedMinute != null) {
      setState(() {
        _dailyMotivationTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      });
    }
    await _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    try {
      int? userId = await _preferencesService.getUserId();
      final loc = Provider.of<LocalizationService>(context, listen: false);
      if (userId != null) {
        // Bildirimleri yükle
        List<Map<String, dynamic>> dbNotifications = await _databaseHelper.getNotifications(userId);
        
        // İlaçları yükle
        List<Map<String, dynamic>> dbMedications = await _databaseHelper.getMedications(userId);
        
        // Su takibini yükle
        int todayWater = await _databaseHelper.getTodayWaterIntake(userId);
        
        if (!mounted) return;
        setState(() {
          notifications = dbNotifications.isNotEmpty
              ? _normalizeNotifications(dbNotifications, loc)
              : _buildSampleNotifications(loc);
          medications = dbMedications.isNotEmpty
              ? _normalizeMedications(dbMedications)
              : exampleMedications;
          waterCount = todayWater;
          isLoading = false;
        });
      } else {
        // Kullanıcı girişi yapılmamış, örnek verileri kullan
        if (!mounted) return;
        setState(() {
          notifications = _buildSampleNotifications(loc);
          medications = exampleMedications;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification data: $e');
      if (!mounted) return;
      setState(() {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        notifications = _buildSampleNotifications(loc);
        medications = exampleMedications;
        isLoading = false;
      });
    }
  }

  Future<void> _createNotification(String title, String message, String type) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _databaseHelper.createNotification(userId, title, message, type);
        _loadNotificationData(); // Listeyi yenile
      }
    } catch (e) {
      print('Notification create error: $e');
    }
  }

  Future<void> _addMedication(String name, String dosage, String frequency, String time) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _databaseHelper.addMedication(userId, name, dosage, frequency, time);
        _loadNotificationData(); // Listeyi yenile
      }
    } catch (e) {
      print('Medication add error: $e');
    }
  }

  Future<void> _updateWaterCount(int newCount) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _databaseHelper.logWaterIntake(userId, newCount);
        if (!mounted) return;
        setState(() {
          waterCount = newCount;
        });
        
  // When goal is reached, create a notification
        if (newCount >= waterGoal) {
          final loc = Provider.of<LocalizationService>(context, listen: false);
          await _createNotification(
            '🎉 ${loc.getString('water_goal_completed_title')}',
            loc.getString('water_goal_completed_message').replaceFirst('{goal}', waterGoal.toString()),
            'water_achievement'
          );
        }
      }
    } catch (e) {
      print('Water tracking update error: $e');
      if (!mounted) return;
      setState(() {
  waterCount = newCount; // At least update the UI
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: notification['color'],
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 20,
                ),
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
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                              color: const Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                        if (!notification['isRead'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53E3E),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              if (notification['type'] == 'motivational') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: notification['description'] as String));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getString('quote_copied'))),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: Text(Provider.of<LocalizationService>(context, listen: false).getString('share_quote')),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          // Rotate by rebuilding sample data next reload; for DB items leave as is
                          if (notifications.isNotEmpty && notifications.first['type'] == 'motivational') {
                            final loc = Provider.of<LocalizationService>(context, listen: false);
                            final list = [
                              loc.getString('motivational_custom_quote'),
                              loc.getString('motivational_message_long'),
                            ].where((e) => e.isNotEmpty).toList();
                            if (list.length > 1) {
                              final current = notifications.first['description'] as String;
                              final nextIndex = (list.indexOf(current) + 1) % list.length;
                              notifications.first['description'] = list[nextIndex];
                            }
                          }
                        });
                      },
                      child: const Icon(Icons.refresh, size: 18),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${notification['date']} • ${notification['time']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Row(
                children: [
                  if (!notification['isRead'])
                    TextButton(
                      onPressed: () => _markAsRead(notification['id']),
                      child: Text(Provider.of<LocalizationService>(context, listen: false).getString('mark_read'), style: const TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Icons.info, size: 16),
                            const SizedBox(width: 8),
                            Text(Provider.of<LocalizationService>(context, listen: false).getString('details')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'why',
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline, size: 16),
                            const SizedBox(width: 8),
                            Text(Provider.of<LocalizationService>(context, listen: false).getString('why_did_i_get_this')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 16),
                            const SizedBox(width: 8),
                            Text(Provider.of<LocalizationService>(context, listen: false).getString('delete')),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'details') _showNotificationDetails(notification);
                      if (value == 'why') _showWhyDidIGetThis(notification);
                      if (value == 'delete') _deleteNotification(notification['id']);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker() {
    double progress = waterCount / waterGoal;
    
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
              Text(
                Provider.of<LocalizationService>(context, listen: false).getString('daily_water_tracking'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Circular Progress
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
                    '$waterCount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ $waterGoal',
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
                onPressed: waterCount > 0 ? () => _updateWaterCount(waterCount - 1) : null,
                icon: const Icon(Icons.remove, size: 16),
                label: Text(Provider.of<LocalizationService>(context, listen: false).getString('water_decrease')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: waterCount < 12 ? () => _updateWaterCount(waterCount + 1) : null,
                icon: const Icon(Icons.add, size: 16),
                label: Text(Provider.of<LocalizationService>(context, listen: false).getString('water_increase')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          
          if (waterCount >= waterGoal) ...[
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
                      Provider.of<LocalizationService>(context, listen: false).getString('water_goal_completed_inline'),
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

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    double progress = medication['completed_days'] / medication['total_days'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
                  color: medication['taken_today'] ? Colors.green.withValues(alpha: 0.1) : const Color(0xFFE53E3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  medication['taken_today'] ? Icons.check : Icons.medication,
                  color: medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    Text(
                      '${medication['dosage']} • ${medication['frequency']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${Provider.of<LocalizationService>(context, listen: false).getString('time_label')}: ${medication['time']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: medication['taken_today'],
                onChanged: (value) {
                  setState(() {
                    medication['taken_today'] = value;
                    if (value && medication['completed_days'] < medication['total_days']) {
                      medication['completed_days']++;
                    }
                  });
                },
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
          Provider.of<LocalizationService>(context, listen: false)
            .getString('med_progress')
            .replaceFirst('{completed}', medication['completed_days'].toString())
            .replaceFirst('{total}', medication['total_days'].toString()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Provider.of<LocalizationService>(context, listen: false).getString('notification_settings_title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 24),
          // Daily motivation scheduler
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule, color: Color(0xFFE53E3E), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Provider.of<LocalizationService>(context, listen: false).getString('daily_motivation_time'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _dailyMotivationTime == null
                            ? '--:--'
                            : _dailyMotivationTime!.format(context),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _dailyMotivationTime ?? TimeOfDay(hour: 8, minute: 0));
                    if (picked != null) {
                      setState(() => _dailyMotivationTime = picked);
                      // Schedule via in-app notification service (simple timer loop)
                      final now = DateTime.now();
                      final first = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                      final firstTime = first.isAfter(now) ? first : first.add(const Duration(days: 1));
                      final loc = Provider.of<LocalizationService>(context, listen: false);
                      final quote = loc.getString('motivational_custom_quote').isNotEmpty
                          ? loc.getString('motivational_custom_quote')
                          : loc.getString('motivational_message_long');
                      // Persist selected time
                      await _preferencesService.saveCustomSettings('daily_motivation_hour', picked.hour);
                      await _preferencesService.saveCustomSettings('daily_motivation_minute', picked.minute);
                      // Schedule notification
                      inapp.NotificationService().addNotification(
                        inapp.NotificationItem(
                          title: '🌟 ${loc.getString('motivational_message')}',
                          description: quote,
                          scheduledTime: firstTime,
                          type: inapp.NotificationType.general,
                          repeatType: inapp.RepeatType.daily,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${loc.getString('daily_motivation_time')}: ${picked.format(context)}')),
                      );
                    }
                  },
                  child: Text(Provider.of<LocalizationService>(context, listen: false).getString('edit')),
                ),
              ],
            ),
          ),
          
          ...reminderSettings.entries.map((entry) {
            String title = _getSettingTitle(entry.key);
            String subtitle = _getSettingSubtitle(entry.key);
            IconData icon = _getSettingIcon(entry.key);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFFE53E3E), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: entry.value,
                    onChanged: (value) {
                      setState(() {
                        reminderSettings[entry.key] = value;
                      });
                    },
                    activeThumbColor: const Color(0xFFE53E3E),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Provider.of<LocalizationService>(context, listen: false).getString('notification_settings_saved')),
                  backgroundColor: const Color(0xFFE53E3E),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: Text(Provider.of<LocalizationService>(context, listen: false).getString('save_settings')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _getSettingTitle(String key) {
  return Provider.of<LocalizationService>(context, listen: false)
    .getString('setting_title_$key');
  }

  String _getSettingSubtitle(String key) {
  return Provider.of<LocalizationService>(context, listen: false)
    .getString('setting_subtitle_$key');
  }

  IconData _getSettingIcon(String key) {
    switch (key) {
      case 'test_reminders': return Icons.bloodtype;
      case 'critical_alerts': return Icons.warning;
      case 'medication_reminders': return Icons.medication;
      case 'nutrition_tips': return Icons.restaurant;
      case 'personalized_diet': return Icons.restaurant_menu;
      case 'motivational_messages': return Icons.favorite;
      case 'health_tips': return Icons.lightbulb;
      case 'smart_meals': return Icons.dining;
      case 'stress_management': return Icons.self_improvement;
      case 'weekly_reports': return Icons.star;
      case 'appointment_reminders': return Icons.calendar_today;
      case 'water_reminders': return Icons.water_drop;
      case 'exercise_reminders': return Icons.fitness_center;
      default: return Icons.notifications;
    }
  }

  Future<void> _markAsRead(dynamic id) async {
    try {
      // Try to persist if ID is numeric (DB-backed notification)
      final intId = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (intId != null) {
        await _databaseHelper.markNotificationAsRead(intId);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      final idx = notifications.indexWhere((n) => n['id'] == id.toString());
      if (idx != -1) notifications[idx]['isRead'] = true;
    });
  }

  Future<void> _deleteNotification(dynamic id) async {
    try {
      final intId = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (intId != null) {
        await _databaseHelper.deleteNotification(intId);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      notifications.removeWhere((n) => n['id'] == id.toString());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getString('notification_deleted'))),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['description']),
            const SizedBox(height: 16),
            Text(
              '${Provider.of<LocalizationService>(context, listen: false).getString('date_label')}: ${notification['date']} ${notification['time']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LocalizationService>(context, listen: false).getString('close')),
          ),
          if (!notification['isRead'])
            ElevatedButton(
              onPressed: () {
                _markAsRead(notification['id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('mark_read_long'), style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(localizationService.getString('notifications')),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE53E3E),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFE53E3E)),
              const SizedBox(height: 16),
              Text(localizationService.getString('loading_data')),
            ],
          ),
        ),
      );
    }
    int unreadCount = notifications.where((n) => !n['isRead']).length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: '/notifications'),
      appBar: AppBar(
        title: Row(
          children: [
            Text(localizationService.getString('notifications')),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53E3E),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: [
            Tab(icon: const Icon(Icons.notifications), text: localizationService.getString('notifications_tab')),
            Tab(icon: const Icon(Icons.water_drop), text: localizationService.getString('water_tracking_tab')),
            Tab(icon: const Icon(Icons.medication), text: localizationService.getString('medications_tab')),
            Tab(icon: const Icon(Icons.settings), text: localizationService.getString('settings_tab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notifications Tab
          notifications.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      localizationService.getString('no_notifications_yet'),
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (unreadCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizationService.getString('unread_notifications_count').replaceFirst('{count}', unreadCount.toString()),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              for (var notification in notifications) {
                                notification['isRead'] = true;
                              }
                            });
                          },
                          child: Text(localizationService.getString('mark_all_read')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...notifications.map((notification) => _buildNotificationCard(notification)),
                ],
              ),
          
          // Water Tracking Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildWaterTracker(),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        localizationService.getString('water_benefits_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizationService.getString('water_benefits_list'),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Medications Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizationService.getString('daily_medication_tracking'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                ...medications.map((medication) => _buildMedicationCard(medication)),
                
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: () => _showAddMedicationDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(localizationService.getString('add_new_medication')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          
          // Settings Tab
          _buildSettingsTab(),
        ],
      ),
    );
  }

  void _showAddMedicationDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
  title: Text(Provider.of<LocalizationService>(context, listen: false).getString('add_new_medication')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('med_name_label'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('dosage_hint'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.science),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: frequencyController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('frequency_hint'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('time_hint'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                onTap: () async {
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    timeController.text = time.format(context);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LocalizationService>(context, listen: false).getString('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _addMedication(
                  nameController.text,
                  dosageController.text.isNotEmpty ? dosageController.text : '1 dose',
                  frequencyController.text.isNotEmpty ? frequencyController.text : 'Once daily',
                  timeController.text.isNotEmpty ? timeController.text : '08:00',
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Provider.of<LocalizationService>(context, listen: false).getString('med_added_success')),
                    backgroundColor: const Color(0xFFE53E3E),
                  ),
                );
                await _createNotification(
                  '💊 ${Provider.of<LocalizationService>(context, listen: false).getString('new_medication_added')}',
                  Provider.of<LocalizationService>(context, listen: false).getString('medication_added_to_list').replaceFirst('{name}', nameController.text),
                  'medication_added'
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Provider.of<LocalizationService>(context, listen: false).getString('med_name_required')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
            child: Text(Provider.of<LocalizationService>(context, listen: false).getString('add'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWhyDidIGetThis(Map<String, dynamic> notification) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
  final pushService = Provider.of<push.PushNotificationService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    // Fetch reason details from push service (may be partial for sample/DB items)
    final String id = notification['id'].toString();
  final reason = pushService.getNotificationReason(id);

    // Log analytics event
    analytics.trackEvent('why_did_i_get_this_open', parameters: {
      'id': id,
      'type': notification['type'] ?? 'general',
      'is_read': notification['isRead'] ?? false,
      'repeat': reason['repeat'] ?? 'unknown',
      'category': reason['category'] ?? 'unknown',
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        Widget kv(String label, Object? value) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${value ?? loc.getString('none')}', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_outline, color: Color(0xFFE53E3E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.getString('why_did_i_get_this'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                kv(loc.getString('reason_scheduled_time'), reason['scheduled_time']),
                kv(loc.getString('reason_received_at'), reason['received_at']),
                kv(loc.getString('reason_repeat'), reason['repeat']),
                kv(loc.getString('reason_reminder_id'), reason['reminder_id']),
                kv(loc.getString('reason_category'), reason['category']),
                kv(loc.getString('reason_hour'), reason['hour']),
                kv(loc.getString('reason_minute'), reason['minute']),
                kv(loc.getString('reason_device_token'), reason['device_token']),
                kv(loc.getString('reason_permission_granted'), reason['permission_granted']),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.getString('close')),
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
