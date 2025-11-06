import 'package:flutter/material.dart';
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

  // Normalize DB medications to UI-friendly shape with real taken status
  Future<List<Map<String, dynamic>>> _normalizeMedications(List<Map<String, dynamic>> raw) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final List<Map<String, dynamic>> normalized = [];
    
    for (var m in raw) {
      final medicationId = m['id'] as int?;
      bool takenToday = false;
      
      if (medicationId != null) {
        try {
          takenToday = await _medicationRepo.wasMedicationTakenToday(medicationId);
        } catch (e) {
          debugPrint('Error checking medication taken status: $e');
        }
      }
      
      // Calculate days from start date if available
      int totalDays = (m['duration_days'] as int?) ?? 30;
      int completedDays = 0;
      
      if (m['start_date'] != null) {
        try {
          final startDate = DateTime.parse(m['start_date'] as String);
          final today = DateTime.now();
          final daysSinceStart = today.difference(startDate).inDays;
          completedDays = daysSinceStart.clamp(0, totalDays);
        } catch (e) {
          debugPrint('Error calculating medication days: $e');
        }
      }
      
      normalized.add({
        'id': medicationId,
        'name': m['name'] ?? loc.getString('medication'),
        'dosage': m['dosage'] ?? loc.getString('default_dosage'),
        'frequency': m['frequency'] ?? loc.getString('default_frequency'),
        'time': m['time'] ?? loc.getString('default_time'),
        'taken_today': takenToday,
        'total_days': totalDays,
        'completed_days': completedDays,
      });
    }
    
    return normalized;
  }
  
  // Localized sample notifications (fallback if DB empty / user not logged in)
  List<Map<String, dynamic>> _buildSampleNotifications(LocalizationService loc) {
    final now = DateTime.now();
    // Format: DD.MM.YYYY (pad with zeros for single digits)
    final dateLabel = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
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
        
        // Normalize medications with real taken status from database
        final normalizedMeds = await _normalizeMedications(dbMedications);
        
        if (!mounted) return;
        setState(() {
      notifications = dbNotifications.isNotEmpty
              ? _normalizeNotifications(dbNotifications, loc)
              : _buildSampleNotifications(loc);
      // Only show real medications from database, no simulations
      medications = normalizedMeds;
          waterCount = todayWater;
          isLoading = false;
        });
      } else {
        // Kullanıcı girişi yapılmamış, örnek bildirimleri göster ama ilaçları gösterme
        if (!mounted) return;
        setState(() {
          notifications = _buildSampleNotifications(loc);
          medications = []; // No medications shown if user not logged in
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification data: $e');
      if (!mounted) return;
        setState(() {
          final loc = Provider.of<LocalizationService>(context, listen: false);
          notifications = _buildSampleNotifications(loc);
          medications = []; // No medications on error, only show real data
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
    // Debug: Log notification count
    debugPrint('Notification count: ${notifications.length}');
    debugPrint('Unread count: $unreadCount');
    
    // Filter notifications based on search and filter
    List<Map<String, dynamic>> filteredNotifications = notifications.where((n) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = (n['title'] ?? '').toString().toLowerCase();
        final description = (n['description'] ?? '').toString().toLowerCase();
        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }
      
      // Category filter
      if (_selectedFilter != null && _selectedFilter != 'all') {
        if (_selectedFilter == 'unread' && (n['isRead'] as bool? ?? false)) return false;
        if (_selectedFilter == 'read' && !(n['isRead'] as bool? ?? false)) return false;
        if (_selectedFilter != 'unread' && _selectedFilter != 'read') {
          if ((n['type'] ?? '').toString() != _selectedFilter) return false;
        }
      }
      
      return true;
    }).toList();
    
    debugPrint('Filtered notification count: ${filteredNotifications.length}');
    
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
        // If no date, assume it's from today (for sample notifications)
        grouped['today']!.add(notif);
        continue;
      }
      
      try {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final date = DateTime(year, month, day);
          final notifDate = DateTime(date.year, date.month, date.day);
          
          if (notifDate == today) {
            grouped['today']!.add(notif);
          } else if (notifDate == yesterday) {
            grouped['yesterday']!.add(notif);
          } else {
            grouped['older']!.add(notif);
          }
        } else {
          // If date format is wrong, assume today to ensure visibility
          grouped['today']!.add(notif);
        }
      } catch (e) {
        debugPrint('Error parsing notification date: $dateStr, error: $e');
        // On error, assume today to ensure notifications are visible
        grouped['today']!.add(notif);
      }
    }
    
    return ListView(
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
              
              // Show empty state if no notifications
              if (filteredNotifications.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc.getString('no_notifications_yet'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bildirimler burada görünecek',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              // Today's Notifications
              if (grouped['today']!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                Text(
                  loc.getString('today') == 'today' ? 'Bugün' : loc.getString('today'),
                  style: TextStyle(
                          fontSize: 16,
                    fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${grouped['today']!.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['today']!.map((notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 24),
              ],
              
              // Yesterday's Notifications
              if (grouped['yesterday']!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[400]!,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                Text(
                  loc.getString('yesterday') == 'yesterday' ? 'Dün' : loc.getString('yesterday'),
                  style: TextStyle(
                          fontSize: 16,
                    fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${grouped['yesterday']!.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['yesterday']!.map((notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 24),
              ],
              
              // Older Notifications
              if (grouped['older']!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[500]!,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                Text(
                  loc.getString('older') == 'older' ? 'Önceki' : loc.getString('older'),
                  style: TextStyle(
                          fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${grouped['older']!.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['older']!.map((notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 24),
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
    final notifColor = notification['color'] as Color;
    final isRead = notification['isRead'] as bool? ?? false;
    final description = notification['description'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isRead 
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  notifColor.withValues(alpha: 0.08),
                  notifColor.withValues(alpha: 0.03),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15))
                : notifColor.withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: isRead ? 6 : 12,
            offset: Offset(0, isRead ? 3 : 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Mark as read on tap
            if (!isRead) {
              setState(() {
                notification['isRead'] = true;
              });
              // Update in database if notification has ID
              if (notification['id'] != null) {
                try {
                  final id = int.tryParse(notification['id'].toString());
                  if (id != null) {
                    _notificationRepo.markAsRead(id);
                  }
                } catch (e) {
                  debugPrint('Error marking notification as read: $e');
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isRead 
                  ? (isDark ? const Color(0xFF1E1E1E) : Colors.grey[50])
                  : (isDark ? const Color(0xFF161B22) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRead 
                    ? (isDark ? const Color(0xFF30363D) : Colors.grey[200]!)
                    : notifColor.withValues(alpha: 0.4),
                width: isRead ? 1 : 2.5,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    // Modern icon with gradient background
              Container(
                      width: 60,
                      height: 60,
                decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            notifColor.withValues(alpha: 0.25),
                            notifColor.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: notifColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: notifColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Icon(
                  notification['icon'],
                        color: notifColor,
                        size: 30,
                ),
              ),
                    const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                                  notification['title'] ?? '',
                            style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isRead)
                          Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: notifColor,
                              shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: notifColor.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                            ),
                          ),
                      ],
                    ),
                          const SizedBox(height: 6),
                          if (notification['subtitle'] != null && (notification['subtitle'] as String).isNotEmpty)
                    Text(
                      notification['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
                // Description with modern styling
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.black.withValues(alpha: 0.3)
                          : notifColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notifColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                // Time and actions row
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification['time'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
            children: [
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  notifColor.withValues(alpha: 0.2),
                                  notifColor.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: notifColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Yeni',
                style: TextStyle(
                  fontSize: 12,
                                color: notifColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                    itemBuilder: (context) => [
                            if (!isRead)
                      PopupMenuItem(
                                value: 'mark_read',
                        child: Row(
                          children: [
                                    Icon(Icons.check_circle, size: 18, color: notifColor),
                                    const SizedBox(width: 12),
                                    Text(Provider.of<LocalizationService>(context, listen: false).getString('mark_read')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                              value: 'details',
                        child: Row(
                          children: [
                                  const Icon(Icons.info_outline, size: 18),
                                  const SizedBox(width: 12),
                                  Text(Provider.of<LocalizationService>(context, listen: false).getString('details')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text(
                                    Provider.of<LocalizationService>(context, listen: false).getString('delete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                            if (value == 'mark_read') {
                              _markAsRead(notification['id']);
                            } else if (value == 'details') {
                              _showNotificationDetails(notification);
                            } else if (value == 'delete') {
                              _deleteNotification(notification['id']);
                            }
                    },
                  ),
                ],
              ),
            ],
                ),
                // Motivational quote actions
                if (notification['type'] == 'motivational' && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: description));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(Provider.of<LocalizationService>(context, listen: false).getString('quote_copied')),
                                backgroundColor: notifColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: Text(
                            Provider.of<LocalizationService>(context, listen: false).getString('share_quote'),
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: BorderSide(color: notifColor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
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
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: Provider.of<LocalizationService>(context, listen: false).getString('new_quote'),
                        style: IconButton.styleFrom(
                          backgroundColor: notifColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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
                onChanged: (value) async {
                  try {
                    int? userId = await _preferencesService.getUserId();
                    if (userId != null && medication['id'] != null) {
                      // Update in database
                      await _medicationRepo.updateMedicationTaken(
                        medication['id'],
                        userId,
                        value,
                      );
                    }
                  setState(() {
                    medication['taken_today'] = value;
                    if (value && medication['completed_days'] < medication['total_days']) {
                      medication['completed_days']++;
                    }
                  });
                  } catch (e) {
                    debugPrint('Error updating medication taken status: $e');
                  }
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
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final bool isDark = themeService.isDarkMode;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    
    // Group settings by category for better organization
    final criticalSettings = [
      'critical_alerts',
      'test_reminders',
    ];
    final healthSettings = [
      'medication_reminders',
      'water_reminders',
      'exercise_reminders',
    ];
    final dietSettings = [
      'nutrition_tips',
      'personalized_diet',
      'smart_meals',
    ];
    final motivationSettings = [
      'motivational_messages',
      'health_tips',
      'stress_management',
    ];
    final otherSettings = [
      'weekly_reports',
      'appointment_reminders',
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE53E3E),
                  const Color(0xFFE53E3E).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getString('notification_settings_title') == 'notification_settings_title'
                            ? 'Notification Permissions'
                            : loc.getString('notification_settings_title'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your notification preferences',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Daily Motivation Time Section
          _buildModernSettingCard(
            icon: Icons.schedule,
            iconColor: const Color(0xFFE53E3E),
            title: loc.getString('daily_motivation_time'),
            subtitle: _dailyMotivationTime == null
                ? 'Tap to set time'
                : _dailyMotivationTime!.format(context),
            isDark: isDark,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE53E3E).withValues(alpha: 0.1),
                    const Color(0xFFE53E3E).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: TextButton.icon(
                  onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _dailyMotivationTime ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                    if (picked != null) {
                      setState(() => _dailyMotivationTime = picked);
                      final now = DateTime.now();
                      final first = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                      final firstTime = first.isAfter(now) ? first : first.add(const Duration(days: 1));
            final quote = DailyAdviceService().getTodayQuoteText(loc);
                      await _preferencesService.saveCustomSettings('daily_motivation_hour', picked.hour);
                      await _preferencesService.saveCustomSettings('daily_motivation_minute', picked.minute);
                      inapp.NotificationService().addNotification(
                        inapp.NotificationItem(
                          title: '🌟 ${loc.getString('motivational_message')}',
                          description: quote,
                          scheduledTime: firstTime,
                          type: inapp.NotificationType.general,
                          repeatType: inapp.RepeatType.daily,
                        ),
                      );
                    if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${loc.getString('daily_motivation_time')}: ${picked.format(context)}'),
                        backgroundColor: const Color(0xFFE53E3E),
                      ),
                      );
                    }
                  },
                icon: const Icon(Icons.edit, size: 16, color: Color(0xFFE53E3E)),
                label: Text(
                  loc.getString('edit'),
                  style: const TextStyle(
                    color: Color(0xFFE53E3E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Critical Settings Section
          if (criticalSettings.any((key) => reminderSettings.containsKey(key))) ...[
            _buildSectionHeader('Critical Alerts', Icons.warning, isDark),
            const SizedBox(height: 12),
            ...criticalSettings.map((key) => reminderSettings.containsKey(key)
                ? _buildModernSwitchSetting(
                    key: key,
                    isDark: isDark,
                    loc: loc,
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
          ],
          
          // Health Settings Section
          if (healthSettings.any((key) => reminderSettings.containsKey(key))) ...[
            _buildSectionHeader('Health & Wellness', Icons.favorite, isDark),
            const SizedBox(height: 12),
            ...healthSettings.map((key) => reminderSettings.containsKey(key)
                ? _buildModernSwitchSetting(
                    key: key,
                    isDark: isDark,
                    loc: loc,
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
          ],
          
          // Diet Settings Section
          if (dietSettings.any((key) => reminderSettings.containsKey(key))) ...[
            _buildSectionHeader('Nutrition & Diet', Icons.restaurant, isDark),
            const SizedBox(height: 12),
            ...dietSettings.map((key) => reminderSettings.containsKey(key)
                ? _buildModernSwitchSetting(
                    key: key,
                    isDark: isDark,
                    loc: loc,
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
          ],
          
          // Motivation Settings Section
          if (motivationSettings.any((key) => reminderSettings.containsKey(key))) ...[
            _buildSectionHeader('Motivation & Tips', Icons.lightbulb, isDark),
            const SizedBox(height: 12),
            ...motivationSettings.map((key) => reminderSettings.containsKey(key)
                ? _buildModernSwitchSetting(
                    key: key,
                    isDark: isDark,
                    loc: loc,
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
          ],
          
          // Other Settings Section
          if (otherSettings.any((key) => reminderSettings.containsKey(key))) ...[
            _buildSectionHeader('Other', Icons.more_horiz, isDark),
            const SizedBox(height: 12),
            ...otherSettings.map((key) => reminderSettings.containsKey(key)
                ? _buildModernSwitchSetting(
                    key: key,
                    isDark: isDark,
                    loc: loc,
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
          ],
          
          // Save Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53E3E),
                  const Color(0xFFE53E3E).withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.getString('notification_settings_saved') == 'notification_settings_saved'
                                ? 'Settings saved successfully'
                                : loc.getString('notification_settings_saved'),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFE53E3E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save, size: 20),
              label: Text(
                loc.getString('save_settings') == 'save_settings'
                    ? 'Save Settings'
                    : loc.getString('save_settings'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFE53E3E),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
  
  Widget _buildModernSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget child,
  }) {
            return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.05),
            iconColor.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
              ),
              child: Row(
                children: [
                  Container(
              width: 56,
              height: 56,
                    decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                    style: TextStyle(
                            fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                  const SizedBox(height: 4),
                        Text(
                          subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                        ),
                      ],
                    ),
                  ),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildModernSwitchSetting({
    required String key,
    required bool isDark,
    required LocalizationService loc,
  }) {
    final title = _getSettingTitle(key);
    final subtitle = _getSettingSubtitle(key);
    final icon = _getSettingIcon(key);
    final iconColor = _getIconColor(key);
    final isEnabled = reminderSettings[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.08),
                  iconColor.withValues(alpha: 0.03),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isEnabled
                ? iconColor.withValues(alpha: 0.15)
                : (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1)),
            blurRadius: isEnabled ? 8 : 4,
            offset: Offset(0, isEnabled ? 3 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
                      setState(() {
              reminderSettings[key] = !isEnabled;
                      });
                    },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isEnabled
                    ? iconColor.withValues(alpha: 0.4)
                    : (isDark ? const Color(0xFF30363D) : Colors.grey[200]!),
                width: isEnabled ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isEnabled
                          ? [
                              iconColor.withValues(alpha: 0.25),
                              iconColor.withValues(alpha: 0.15),
                            ]
                          : [
                              Colors.grey.withValues(alpha: 0.1),
                              Colors.grey.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEnabled
                          ? iconColor.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? iconColor : Colors.grey[400],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isEnabled ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEnabled
                          ? iconColor.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        reminderSettings[key] = value;
                      });
                    },
                    activeColor: iconColor,
                    activeTrackColor: iconColor.withValues(alpha: 0.5),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getIconColor(String key) {
    switch (key) {
      case 'test_reminders':
      case 'critical_alerts':
        return Colors.red;
      case 'medication_reminders':
        return Colors.blue;
      case 'water_reminders':
        return Colors.cyan;
      case 'exercise_reminders':
        return Colors.orange;
      case 'nutrition_tips':
      case 'personalized_diet':
      case 'smart_meals':
        return Colors.green;
      case 'motivational_messages':
        return Colors.pink;
      case 'health_tips':
        return Colors.purple;
      case 'stress_management':
        return Colors.indigo;
      case 'weekly_reports':
        return Colors.amber;
      case 'appointment_reminders':
        return Colors.teal;
      default:
        return const Color(0xFFE53E3E);
    }
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
