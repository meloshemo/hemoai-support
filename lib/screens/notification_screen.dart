import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/color_compat.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';
import '../services/theme_service.dart';
// Repositories (SSoT)
import '../repositories/notification_repository.dart';
import '../repositories/medication_repository.dart';
import '../repositories/water_repository.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart' as inapp;
import '../services/daily_advice_service.dart';
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
  late final NotificationRepository _notificationRepo;
  late final MedicationRepository _medicationRepo;
  late final WaterRepository _waterRepo;
  final PreferencesService _preferencesService = PreferencesService();
  TimeOfDay? _dailyMotivationTime;
  List<String> _motivationQuotes = const [];
  int _motivationIndex = 0;
  
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> medications = [];
  bool isLoading = true;
  String _searchQuery = '';
  String? _selectedFilter; // 'all', 'unread', 'motivational', 'diet', 'reminder'
  
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
    final quotes = DailyAdviceService().getAllQuotes(loc);
    final todayQuote = DailyAdviceService().getTodayQuoteText(loc);
    return [
  {
        'id': '1',
  'title': '🌟 ${loc.getString('motivational_message')}',
    'subtitle': loc.getString('take_care_today'),
    'description': todayQuote.isNotEmpty
        ? todayQuote
        : (quotes.isNotEmpty ? quotes.first : loc.getString('motivational_message_long')),
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

  // Sample medications (localized at build-time)
  List<Map<String, dynamic>> _exampleMedications(LocalizationService loc) => [
    {
      'name': loc.getString('iron_supplement'),
      'dosage': '1 ${loc.getString('unit_tablet')}',
      'frequency': loc.getString('frequency_once_daily'),
      'time': '20:00',
      'taken_today': true,
      'total_days': 30,
      'completed_days': 15,
    },
    {
      'name': 'Vitamin B12',
      'dosage': '1 ${loc.getString('unit_capsule')}',
      'frequency': loc.getString('frequency_twice_weekly'),
      'time': '09:00',
      'taken_today': false,
      'total_days': 60,
      'completed_days': 8,
    },
    {
      'name': loc.getString('folic_acid'),
      'dosage': '1 ${loc.getString('unit_tablet')}',
      'frequency': loc.getString('frequency_once_daily'),
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
    // Repositories
    _notificationRepo = Provider.of<NotificationRepository>(context, listen: false);
    _medicationRepo = Provider.of<MedicationRepository>(context, listen: false);
    _waterRepo = Provider.of<WaterRepository>(context, listen: false);
    _initializePrefsAndData();
    // Load all motivation quotes for rotation UI
    final loc = LocalizationService();
    _motivationQuotes = DailyAdviceService().getAllQuotes(loc);
    _motivationIndex = 0;
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
  List<Map<String, dynamic>> dbNotifications = await _notificationRepo.getNotifications(userId);
        
        // İlaçları yükle
  List<Map<String, dynamic>> dbMedications = await _medicationRepo.getMedications(userId);
        
        // Su takibini yükle
  int todayWater = await _waterRepo.getTodayWaterIntake(userId);
        
        if (!mounted) return;
        setState(() {
      notifications = dbNotifications.isNotEmpty
              ? _normalizeNotifications(dbNotifications, loc)
              : _buildSampleNotifications(loc);
      medications = dbMedications.isNotEmpty
        ? _normalizeMedications(dbMedications)
        : _exampleMedications(loc);
          waterCount = todayWater;
          isLoading = false;
        });
      } else {
        // Kullanıcı girişi yapılmamış, örnek verileri kullan
        if (!mounted) return;
        setState(() {
          notifications = _buildSampleNotifications(loc);
          medications = _exampleMedications(loc);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification data: $e');
      if (!mounted) return;
        setState(() {
          final loc = Provider.of<LocalizationService>(context, listen: false);
          notifications = _buildSampleNotifications(loc);
          medications = _exampleMedications(loc);
          isLoading = false;
        });
    }
  }

  Future<void> _createNotification(String title, String message, String type) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _notificationRepo.createNotification(userId: userId, title: title, message: message, type: type);
        _loadNotificationData(); // Listeyi yenile
      }
    } catch (e) {
      debugPrint('Notification create error: $e');
    }
  }

  Future<void> _addMedication(String name, String dosage, String frequency, String time) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _medicationRepo.addMedication(userId: userId, name: name, dosage: dosage, frequency: frequency, time: time);
        _loadNotificationData(); // Listeyi yenile
      }
    } catch (e) {
      debugPrint('Medication add error: $e');
    }
  }

  Future<void> _updateWaterCount(int newCount) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
  await _waterRepo.logWaterIntake(userId: userId, amount: newCount);
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
      debugPrint('Water tracking update error: $e');
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

  Widget _buildNotificationsTab(bool isDark, LocalizationService loc, int unreadCount) {
    // Filter notifications based on search and filter
    List<Map<String, dynamic>> filteredNotifications = notifications.where((n) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!n['title'].toString().toLowerCase().contains(query) &&
            !n['description'].toString().toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Category filter
      if (_selectedFilter != null && _selectedFilter != 'all') {
        if (_selectedFilter == 'unread' && n['isRead']) return false;
        if (_selectedFilter == 'read' && !n['isRead']) return false;
        if (_selectedFilter != 'unread' && _selectedFilter != 'read') {
          if (n['type'] != _selectedFilter) return false;
        }
      }
      
      return true;
    }).toList();
    
    // Group by date (today, yesterday, older)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    Map<String, List<Map<String, dynamic>>> grouped = {
      'today': [],
      'yesterday': [],
      'older': [],
    };
    
    for (var notif in filteredNotifications) {
      final dateStr = notif['date'] ?? '';
      if (dateStr.isEmpty) {
        grouped['older']!.add(notif);
        continue;
      }
      
      try {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          final notifDate = DateTime(date.year, date.month, date.day);
          
          if (notifDate == today) {
            grouped['today']!.add(notif);
          } else if (notifDate == yesterday) {
            grouped['yesterday']!.add(notif);
          } else {
            grouped['older']!.add(notif);
          }
        } else {
          grouped['older']!.add(notif);
        }
      } catch (_) {
        grouped['older']!.add(notif);
      }
    }
    
    return filteredNotifications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: isDark ? Colors.grey[600] : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.getString('no_notifications_yet'),
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF30363D) : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: loc.getString('search_notifications') == 'search_notifications' 
                        ? 'Bildirimlerde ara...' 
                        : loc.getString('search_notifications'),
                    hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', loc.getString('all') == 'all' ? 'Tümü' : loc.getString('all'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('unread', loc.getString('unread') == 'unread' ? 'Okunmamış' : loc.getString('unread'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('motivational', loc.getString('motivational_message'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('personalized_diet', loc.getString('diet'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('test_reminder', loc.getString('reminder'), isDark, loc),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (unreadCount > 0)
                    Text(
                      loc.getString('unread_notifications_count').replaceFirst('{count}', unreadCount.toString()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE53E3E) : const Color(0xFFE53E3E),
                      ),
                    ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/all_quotes'),
                        icon: Icon(Icons.format_quote, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        label: Text(
                          loc.getString('view_all_quotes'),
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              for (var notification in notifications) {
                                notification['isRead'] = true;
                              }
                            });
                          },
                          child: Text(
                            loc.getString('mark_all_read'),
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Today's Notifications
              if (grouped['today']!.isNotEmpty) ...[
                Text(
                  loc.getString('today') == 'today' ? 'Bugün' : loc.getString('today'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['today']!.map((notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 16),
              ],
              
              // Yesterday's Notifications
              if (grouped['yesterday']!.isNotEmpty) ...[
                Text(
                  loc.getString('yesterday') == 'yesterday' ? 'Dün' : loc.getString('yesterday'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['yesterday']!.map((notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 16),
              ],
              
              // Older Notifications
              if (grouped['older']!.isNotEmpty) ...[
                Text(
                  loc.getString('older') == 'older' ? 'Önceki' : loc.getString('older'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['older']!.map((notification) => _buildNotificationCard(notification)),
              ],
            ],
          );
  }

  Widget _buildFilterChip(String value, String label, bool isDark, LocalizationService loc) {
    final isSelected = _selectedFilter == value || (_selectedFilter == null && value == 'all');
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : null;
        });
      },
      selectedColor: const Color(0xFFE53E3E).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFFE53E3E),
      labelStyle: TextStyle(
        color: isSelected 
            ? const Color(0xFFE53E3E)
            : (isDark ? Colors.grey[300] : Colors.grey[700]),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? const Color(0xFFE53E3E)
            : (isDark ? const Color(0xFF30363D) : Colors.grey[300]!),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead'] 
            ? (isDark ? const Color(0xFF1E1E1E) : Colors.grey[50])
            : (isDark ? const Color(0xFF161B22) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: notification['color'],
            width: 4,
          ),
          right: BorderSide(
            color: isDark ? const Color(0xFF30363D) : Colors.transparent,
            width: 0.5,
          ),
          top: BorderSide(
            color: isDark ? const Color(0xFF30363D) : Colors.transparent,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: isDark ? const Color(0xFF30363D) : Colors.transparent,
            width: 0.5,
          ),
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
                              color: isDark ? const Color(0xFFE53E3E) : const Color(0xFFE53E3E),
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
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                          if (_motivationQuotes.isEmpty) {
                            final loc = Provider.of<LocalizationService>(context, listen: false);
                            _motivationQuotes = DailyAdviceService().getAllQuotes(loc);
                          }
                          if (_motivationQuotes.isNotEmpty) {
                            _motivationIndex = (_motivationIndex + 1) % _motivationQuotes.length;
                            final idx = notifications.indexWhere((n) => n['type'] == 'motivational');
                            if (idx != -1) {
                              notifications[idx]['description'] = _motivationQuotes[_motivationIndex];
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
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
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

  String _localizedFrequency(String s, LocalizationService loc) {
    final t = s.trim();
    switch (t.toLowerCase()) {
      case 'once daily':
        return loc.getString('frequency_once_daily');
      case 'twice daily':
        return loc.getString('frequency_twice_daily');
      case 'three times daily':
        return loc.getString('frequency_three_times_daily');
      case 'once weekly':
        return loc.getString('frequency_once_weekly');
      case 'twice weekly':
        return loc.getString('frequency_twice_weekly');
      case 'every other day':
        return loc.getString('frequency_every_other_day');
      default:
        return t;
    }
  }

  String _localizedDosage(String s, LocalizationService loc) {
    var out = s;
    out = out.replaceAll(RegExp(r'\btablet\b', caseSensitive: false), loc.getString('unit_tablet'));
    out = out.replaceAll(RegExp(r'\bcapsule\b', caseSensitive: false), loc.getString('unit_capsule'));
    out = out.replaceAll(RegExp(r'\bdose\b', caseSensitive: false), loc.getString('unit_dose'));
    return out;
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    double progress = medication['completed_days'] / medication['total_days'];
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final dosageText = _localizedDosage(medication['dosage'].toString(), loc);
    final freqText = _localizedFrequency(medication['frequency'].toString(), loc);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
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
                      '$dosageText • $freqText',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${Provider.of<LocalizationService>(context, listen: false).getString('time_label')}: ${medication['time']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey[300]!),
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
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
            final quote = DailyAdviceService().getTodayQuoteText(loc);
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
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey[300]!),
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
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
  await _notificationRepo.markAsRead(intId);
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
  await _notificationRepo.delete(intId);
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
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);
    final isDark = themeService.isDarkMode;
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
        drawer: const AppDrawer(currentRoute: '/notifications'),
        appBar: UnifiedAppBar(
          title: localizationService.getString('notifications'),
          currentRoute: '/notifications',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFE53E3E)),
              const SizedBox(height: 16),
              Text(
                localizationService.getString('loading_data'),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      );
    }
    int unreadCount = notifications.where((n) => !n['isRead']).length;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
      drawer: const AppDrawer(currentRoute: '/notifications'),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                localizationService.getString('notifications'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Color(0xFFE53E3E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
          _buildNotificationsTab(isDark, localizationService, unreadCount),
          
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
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: isDark 
                        ? Border.all(color: const Color(0xFF30363D), width: 0.5)
                        : null,
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
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                        ),
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
                  dosageController.text.isNotEmpty ? dosageController.text : Provider.of<LocalizationService>(context, listen: false).getString('default_dosage'),
                  frequencyController.text.isNotEmpty ? frequencyController.text : Provider.of<LocalizationService>(context, listen: false).getString('frequency_once_daily'),
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
