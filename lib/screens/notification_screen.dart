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
import '../services/push_notification_service.dart' as push
    show PushNotificationService;
import '../services/analytics_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
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
  String?
      _selectedFilter; // 'all', 'unread', 'motivational', 'diet', 'reminder'
  // Use localization keys for frequency options; values will be fetched from LocalizationService
  static const List<String> _frequencyKeys = [
    'frequency_once_daily',
    'frequency_twice_daily',
    'frequency_three_times_daily',
    'frequency_once_weekly',
    'frequency_twice_weekly',
    'frequency_every_other_day',
  ];

  // Derive canonical storage value (english, lower-case) from key to avoid hardcoded UI literals
  String _canonicalFrequencyFromKey(String key) {
    if (!key.startsWith('frequency_')) {
      // Fallback to localized once daily
      return LocalizationService().getString('frequency_once_daily');
    }
    final raw = key.substring('frequency_'.length).replaceAll('_', ' ');
    // Return localized value for the key
    final loc = LocalizationService();
    final val = loc.getString(key);
    return val != key ? val : raw;
  }

  // Map canonical types to variant key suffixes to fetch detection pattern lists from LocalizationService
  String _variantKeySuffix(String type) {
    switch (type) {
      case 'medication_reminder':
        return 'medication';
      case 'appointment_reminder':
        return 'appointment';
      case 'test_reminder':
        return 'test';
      case 'water_achievement':
        return 'water';
      default:
        return '';
    }
  }

  // Build pattern list from localization (current locale + English) for robust detection
  List<String> _patternList(LocalizationService loc, String key) {
    final List<String> out = [];
    final cur = loc.getString(key);
    if (cur != key) {
      for (final s in cur.split('\n')) {
        final t = s.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    return out;
  }

  String _canonicalType(String? type, {String? title, String? description}) {
    final value = (type ?? '').toLowerCase();
    final loc = Provider.of<LocalizationService>(context, listen: false);
    if (value.contains('medication_added') || value.contains('med_added')) {
      return 'medication_added';
    }
    if (value.contains('medication')) {
      return 'medication_reminder';
    }
    if (value.contains('appointment')) {
      return 'appointment_reminder';
    }
    if (value.contains('test')) {
      return 'test_reminder';
    }
    if (value.contains('water')) {
      return 'water_achievement';
    }
    if (value.contains('motivational')) {
      return 'motivational';
    }
    if (value.contains('diet')) {
      return 'personalized_diet';
    }
    if (value.contains('critical')) {
      return 'critical_alert';
    }
    if (value.contains('weekly')) {
      return 'weekly_report';
    }

    final normalizedTitle = (title ?? '').toLowerCase();
    // Build localized detection patterns (titles/subtitles/bodies)
    List<String> _patternsFor(String suffix) => [
          ..._patternList(loc, 'notification_default_titles_' + suffix),
          ..._patternList(loc, 'notification_default_subtitles_' + suffix),
          ..._patternList(loc, 'notification_default_bodies_' + suffix),
        ]
            .map((e) => e.toLowerCase())
            .toList();

    bool _containsAny(String haystack, List<String> needles) {
      for (final n in needles) {
        if (n.isEmpty) continue;
        if (haystack.contains(n)) return true;
      }
      return false;
    }

    final medPatterns = _patternsFor('medication');
    final apptPatterns = _patternsFor('appointment');
    final testPatterns = _patternsFor('test');

    if (normalizedTitle.contains('medication')) {
      return 'medication_reminder';
    }
    if (normalizedTitle.contains('appointment')) {
      return 'appointment_reminder';
    }
    if (normalizedTitle.contains('test') ||
        normalizedTitle.contains('tahlil')) {
      return 'test_reminder';
    }
    if (_containsAny(normalizedTitle, medPatterns)) {
      return 'medication_reminder';
    }
    if (_containsAny(normalizedTitle, apptPatterns)) {
      return 'appointment_reminder';
    }
    if (_containsAny(normalizedTitle, testPatterns)) {
      return 'test_reminder';
    }
    if (normalizedTitle.contains('water')) {
      return 'water_achievement';
    }
    if (normalizedTitle.contains('motivational') ||
        normalizedTitle.contains('quote')) {
      return 'motivational';
    }

    final normalizedBody = (description ?? '').toLowerCase();
    if (_containsAny(normalizedBody, medPatterns)) {
      return 'medication_reminder';
    }
    if (normalizedBody.contains('appointment') ||
        _containsAny(normalizedBody, apptPatterns)) {
      return 'appointment_reminder';
    }
    if (normalizedBody.contains('test') ||
        _containsAny(normalizedBody, testPatterns)) {
      return 'test_reminder';
    }

    return 'general';
  }

  IconData _iconForType(String? rawType) {
    final type = _canonicalType(rawType);
    switch (type) {
      case 'motivational':
        return Icons.favorite_outline;
      case 'personalized_diet':
        return Icons.restaurant_menu;
      case 'test_reminder':
        return Icons.bloodtype_outlined;
      case 'water_achievement':
        return Icons.water_drop_outlined;
      case 'medication_reminder':
        return Icons.medication_outlined;
      case 'medication_added':
        return Icons.add_box_outlined;
      case 'appointment_reminder':
        return Icons.event_available_outlined;
      case 'weekly_report':
        return Icons.insights_outlined;
      case 'critical_alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _colorForType(String? rawType) {
    final type = _canonicalType(rawType);
    switch (type) {
      case 'motivational':
        return const Color(0xFF6C63FF);
      case 'personalized_diet':
        return const Color(0xFF3AA76D);
      case 'test_reminder':
        return const Color(0xFFE86B6B);
      case 'water_achievement':
        return const Color(0xFF2A9D8F);
      case 'medication_reminder':
        return const Color(0xFF5B8DEF);
      case 'medication_added':
        return const Color(0xFF4CAF50);
      case 'appointment_reminder':
        return const Color(0xFFFFA857);
      case 'weekly_report':
        return const Color(0xFF6D889C);
      case 'critical_alert':
        return const Color(0xFFDC3545);
      default:
        return const Color(0xFF6D889C);
    }
  }

  Map<String, dynamic> _applyLocalizationToNotification(
    Map<String, dynamic> notification,
    Map<String, dynamic> raw,
    LocalizationService loc,
  ) {
    final type = notification['type'] as String? ?? 'general';
    final template = _notificationTemplate(type, raw, loc);
    if (template.isEmpty) {
      return notification;
    }

    List<String>? titlePatterns;
    List<String>? subtitlePatterns;
    List<String>? bodyPatterns;
    final suffix = _variantKeySuffix(type);
    if (suffix.isNotEmpty) {
      titlePatterns = _patternList(loc, 'notification_default_titles_$suffix');
      // subtitle patterns may be missing for some types; guard with existing keys
      subtitlePatterns =
          _patternList(loc, 'notification_default_subtitles_$suffix');
      bodyPatterns = _patternList(loc, 'notification_default_bodies_$suffix');
    }

    notification['title'] = _pickLocalizedValue(
      notification['title']?.toString() ?? '',
      template['title'] ?? notification['title']?.toString() ?? '',
      titlePatterns,
    );

    notification['subtitle'] = _pickLocalizedValue(
      notification['subtitle']?.toString() ?? '',
      template['subtitle'] ?? notification['subtitle']?.toString() ?? '',
      subtitlePatterns,
    );

    notification['description'] = _pickLocalizedValue(
      notification['description']?.toString() ?? '',
      template['description'] ?? notification['description']?.toString() ?? '',
      bodyPatterns,
      allowPartialMatch: true,
    );

    return notification;
  }

  String _pickLocalizedValue(
    String current,
    String fallback,
    List<String>? englishDefaults, {
    bool allowPartialMatch = false,
  }) {
    final trimmed = current.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    if (englishDefaults != null && englishDefaults.isNotEmpty) {
      final lower = trimmed.toLowerCase();
      for (final candidate in englishDefaults) {
        final candidateLower = candidate.toLowerCase();
        final matches = allowPartialMatch
            ? lower.contains(candidateLower)
            : lower == candidateLower;
        if (matches) {
          return fallback;
        }
      }
    }
    return trimmed;
  }

  Map<String, String> _notificationTemplate(
    String type,
    Map<String, dynamic> raw,
    LocalizationService loc,
  ) {
    final message =
        (raw['message'] as String?) ?? (raw['description'] as String?) ?? '';

    switch (type) {
      case 'medication_reminder':
        final medName = _extractMedicationName(message, loc);
        final safeName = (medName?.isNotEmpty ?? false)
            ? medName!
            : loc.getString('notification_medication_generic_name');
        return {
          'title': loc.getString('notification_medication_title'),
          'subtitle': loc.getString('notification_medication_subtitle'),
          'description': loc
              .getString('notification_medication_body')
              .replaceAll('{name}', safeName),
        };
      case 'appointment_reminder':
        final doctor = _extractDoctorName(message);
        final safeDoctor = (doctor?.isNotEmpty ?? false)
            ? doctor!
            : loc.getString('notification_appointment_generic_contact');
        return {
          'title': loc.getString('notification_appointment_title'),
          'subtitle': loc.getString('notification_appointment_subtitle'),
          'description': loc
              .getString('notification_appointment_body')
              .replaceAll('{doctor}', safeDoctor),
        };
      case 'test_reminder':
        final testName = _extractTestName(message);
        final safeTest = (testName?.isNotEmpty ?? false)
            ? testName!
            : loc.getString('notification_test_generic_name');
        return {
          'title': loc.getString('notification_test_title'),
          'subtitle': loc.getString('notification_test_subtitle'),
          'description': loc
              .getString('notification_test_body')
              .replaceAll('{test}', safeTest),
        };
      case 'water_achievement':
        return {
          'title': '🎉 ${loc.getString('water_goal_completed_title')}',
          'subtitle': loc.getString('water_goal_completed_inline'),
          'description': loc
              .getString('water_goal_completed_message')
              .replaceFirst(
                  '{goal}',
                  (raw['goal']?.toString().isNotEmpty ?? false)
                      ? raw['goal'].toString()
                      : waterGoal.toString()),
        };
      default:
        return {};
    }
  }

  String? _extractMedicationName(String message, LocalizationService loc) {
    // Try localized body prefixes (e.g., variants like "It is time to take", "Time to take", etc.)
    final prefixes =
        _patternList(loc, 'notification_default_bodies_medication');
    final lowerMsg = message.toLowerCase();
    for (final p in prefixes) {
      final pl = p.toLowerCase();
      if (lowerMsg.startsWith(pl)) {
        final rest = message.substring(p.length).trim();
        if (rest.isNotEmpty) {
          return rest.replaceAll('.', '');
        }
      }
    }
    // Fallback: pick a capitalized token that looks like a medicine name (avoid Dr.)
    final tokenMatch =
        RegExp(r'([A-Z][a-zA-Z0-9\-]+(?:\s+[A-Z][a-zA-Z0-9\-]+)?)')
            .firstMatch(message);
    final candidate = tokenMatch?.group(1)?.trim();
    if (candidate != null &&
        candidate.isNotEmpty &&
        !candidate.toLowerCase().startsWith('dr')) {
      return candidate.replaceAll('.', '');
    }
    return null;
  }

  String? _extractDoctorName(String message) {
    final match = RegExp(r'appointment with\s+(.*?)\s+(?:is|on|at)\b',
            caseSensitive: false)
        .firstMatch(message);
    if (match != null) {
      final doctor = match.group(1)?.trim();
      if (doctor != null && doctor.isNotEmpty) {
        return doctor.startsWith(RegExp(r'dr', caseSensitive: false))
            ? doctor
            : 'Dr. $doctor';
      }
    }
    return null;
  }

  String? _extractTestName(String message) {
    final match =
        RegExp(r'for your\s+(.*?)\s+(?:test|appointment)', caseSensitive: false)
            .firstMatch(message);
    if (match != null) {
      final test = match.group(1)?.trim();
      if (test != null && test.isNotEmpty) {
        return test;
      }
    }
    final fallback = message.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
    if (fallback.toLowerCase().contains('test')) return null;
    return fallback.isEmpty ? null : fallback;
  }

  String _formatNotificationTimestamp(
      Map<String, dynamic> notification, LocalizationService loc) {
    final dateStr = notification['date']?.toString() ?? '';
    final timeStr = notification['time']?.toString() ?? '';
    if (dateStr.isEmpty && timeStr.isEmpty) return '';
    if (dateStr.isEmpty) return timeStr;
    try {
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        final formattedDate = loc.formatDate(date);
        if (timeStr.isEmpty) return formattedDate;
        return '$formattedDate • $timeStr';
      }
    } catch (_) {
      // ignore parse errors and fall back to raw value
    }
    return timeStr.isEmpty ? dateStr : '$dateStr • $timeStr';
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Normalize DB notifications to UI-friendly shape
  List<Map<String, dynamic>> _normalizeNotifications(
      List<Map<String, dynamic>> raw, LocalizationService loc) {
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

      final rawType = n['type'] as String?;
      final id = n['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final isRead = (n['isRead'] is bool)
          ? (n['isRead'] as bool)
          : ((n['is_read'] is bool) ? (n['is_read'] as bool) : false);
      final title = (n['title'] as String?) ?? loc.getString('notifications');
      final subtitle =
          (n['subtitle'] as String?) ?? loc.getString('no_subtitle');
      // Prefer description; fallback to message
      final description = (n['description'] as String?) ??
          (n['message'] as String?) ??
          loc.getString('no_description');

      final canonicalType =
          _canonicalType(rawType, title: title, description: description);

      final normalized = {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'type': canonicalType,
        'priority': (n['priority'] as String?) ?? 'medium',
        'icon': _iconForType(canonicalType),
        'color': _colorForType(canonicalType),
        'isRead': isRead,
        'date': date,
        'time': time,
      };

      return _applyLocalizationToNotification(normalized, n, loc);
    }).toList();
  }

  // Normalize DB medications to UI-friendly shape
  List<Map<String, dynamic>> _normalizeMedications(
      List<Map<String, dynamic>> raw) {
    return raw.map((m) {
      return {
        'name': m['name'] ??
            Provider.of<LocalizationService>(context, listen: false)
                .getString('medication'),
        'dosage': m['dosage'] ??
            Provider.of<LocalizationService>(context, listen: false)
                .getString('default_dosage'),
        'frequency': m['frequency'] ??
            Provider.of<LocalizationService>(context, listen: false)
                .getString('default_frequency'),
        'time': m['time'] ??
            Provider.of<LocalizationService>(context, listen: false)
                .getString('default_time'),
        'taken_today': (m['taken_today'] is bool) ? m['taken_today'] : false,
        'total_days': (m['total_days'] is int) ? m['total_days'] : 30,
        'completed_days':
            (m['completed_days'] is int) ? m['completed_days'] : 0,
      };
    }).toList();
  }

  // Localized sample notifications (fallback if DB empty / user not logged in)
  List<Map<String, dynamic>> _buildSampleNotifications(
      LocalizationService loc) {
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
            : (quotes.isNotEmpty
                ? quotes.first
                : loc.getString('motivational_message_long')),
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
          'name': loc.getString('vitamin_b12'),
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
    _tabController = TabController(length: 2, vsync: this); // Simplified: Only Unread and All
    // Repositories
    _notificationRepo =
        Provider.of<NotificationRepository>(context, listen: false);
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
    final savedHour =
        _preferencesService.getCustomSetting<int>('daily_motivation_hour');
    final savedMinute =
        _preferencesService.getCustomSetting<int>('daily_motivation_minute');
    if (mounted && savedHour != null && savedMinute != null) {
      setState(() {
        _dailyMotivationTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      });
    }
    await _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    if (!mounted) return;
    final loc = Provider.of<LocalizationService>(context, listen: false);

    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        // Load notifications
        List<Map<String, dynamic>> dbNotifications =
            await _notificationRepo.getNotifications(userId);

        // Load medications
        List<Map<String, dynamic>> dbMedications =
            await _medicationRepo.getMedications(userId);

        // Load today's water intake
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
        // No user logged in; use sample data
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
        notifications = _buildSampleNotifications(loc);
        medications = _exampleMedications(loc);
        isLoading = false;
      });
    }
  }

  Future<void> _createNotification(
      String title, String message, String type) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _notificationRepo.createNotification(
            userId: userId, title: title, message: message, type: type);
        _loadNotificationData(); // Listeyi yenile
      }
    } catch (e) {
      debugPrint('Notification create error: $e');
    }
  }

  Future<void> _addMedication(
      String name, String dosage, String frequency, String time) async {
    try {
      int? userId = await _preferencesService.getUserId();
      if (userId != null) {
        await _medicationRepo.addMedication(
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            time: time);
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
              loc
                  .getString('water_goal_completed_message')
                  .replaceFirst('{goal}', waterGoal.toString()),
              'water_achievement');
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

  Widget _buildUnreadNotificationsTab(
      bool isDark, LocalizationService loc, int unreadCount) {
    // Show only unread notifications - clean and focused
    final unreadNotifications = notifications.where((n) => !(n['isRead'] as bool? ?? false)).toList();
    
    if (unreadNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              loc.getString('no_unread_notifications'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.getString('all_caught_up'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotificationData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: unreadNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildNotificationCard(unreadNotifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationsTab(
      bool isDark, LocalizationService loc, int unreadCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputBackground =
        isDark ? const Color(0xFF1F242C) : colorScheme.surfaceContainerHigh;
    final inputBorderColor =
        colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.25);

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
          final date = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: inputBorderColor),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: loc.getString('search_notifications'),
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.search,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7)),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', loc.getString('all'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'unread', loc.getString('unread'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('motivational',
                        loc.getString('motivational_message'), isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('personalized_diet', loc.getString('diet'),
                        isDark, loc),
                    const SizedBox(width: 8),
                    _buildFilterChip('test_reminder', loc.getString('reminder'),
                        isDark, loc),
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
                      loc
                          .getString('unread_notifications_count')
                          .replaceFirst('{count}', unreadCount.toString()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/all_quotes'),
                        icon: Icon(Icons.format_quote,
                            size: 18, color: colorScheme.onSurfaceVariant),
                        label: Text(
                          loc.getString('view_all_quotes'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
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
                  loc.getString('today'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['today']!.map(
                    (notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 16),
              ],

              // Yesterday's Notifications
              if (grouped['yesterday']!.isNotEmpty) ...[
                Text(
                  loc.getString('yesterday'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['yesterday']!.map(
                    (notification) => _buildNotificationCard(notification)),
                const SizedBox(height: 16),
              ],

              // Older Notifications
              if (grouped['older']!.isNotEmpty) ...[
                Text(
                  loc.getString('older'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...grouped['older']!.map(
                    (notification) => _buildNotificationCard(notification)),
              ],
            ],
          );
  }

  Widget _buildFilterChip(
      String value, String label, bool isDark, LocalizationService loc) {
    final isSelected =
        _selectedFilter == value || (_selectedFilter == null && value == 'all');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedForeground = colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : null;
        });
      },
      selectedColor: selectedForeground.withValues(alpha: isDark ? 0.3 : 0.15),
      checkmarkColor: selectedForeground,
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: isSelected ? selectedForeground : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected
            ? selectedForeground.withValues(alpha: 0.7)
            : colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.2),
      ),
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerHigh,
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final accentColor =
        (notification['color'] as Color?) ?? colorScheme.primary;
    final isUnread = !(notification['isRead'] as bool? ?? false);
    final timestamp = _formatNotificationTimestamp(notification, loc);

    return Card(
      elevation: isUnread ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      surfaceTintColor: colorScheme.surface,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification['icon'] as IconData,
                    color: accentColor,
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
                              notification['title']?.toString() ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['subtitle']?.toString() ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification['description']?.toString() ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (notification['type'] == 'motivational') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(
                            text: notification['description'] as String),
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(loc.getString('quote_copied'))),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(loc.getString('share_quote')),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_motivationQuotes.isEmpty) {
                          _motivationQuotes =
                              DailyAdviceService().getAllQuotes(loc);
                        }
                        if (_motivationQuotes.isNotEmpty) {
                          _motivationIndex =
                              (_motivationIndex + 1) % _motivationQuotes.length;
                          final idx = notifications
                              .indexWhere((n) => n['type'] == 'motivational');
                          if (idx != -1) {
                            notifications[idx]['description'] =
                                _motivationQuotes[_motivationIndex];
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(loc.getString('refresh')),
                  ),
                ],
              ),
            ],
            if (timestamp.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timestamp,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (isUnread)
                  TextButton.icon(
                    onPressed: () => _markAsRead(notification['id']),
                    icon: const Icon(Icons.done, size: 18),
                    label: Text(loc.getString('mark_read')),
                    style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary),
                  ),
                TextButton.icon(
                  onPressed: () => _showNotificationDetails(notification),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(loc.getString('details')),
                  style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary),
                ),
                TextButton.icon(
                  onPressed: () => _showWhyDidIGetThis(notification),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: Text(loc.getString('why_did_i_get_this')),
                  style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary),
                ),
                TextButton.icon(
                  onPressed: () => _deleteNotification(notification['id']),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(loc.getString('delete')),
                  style:
                      TextButton.styleFrom(foregroundColor: colorScheme.error),
                ),
              ],
            ),
          ],
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
                Provider.of<LocalizationService>(context, listen: false)
                    .getString('daily_water_tracking'),
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
                onPressed: waterCount > 0
                    ? () => _updateWaterCount(waterCount - 1)
                    : null,
                icon: const Icon(Icons.remove, size: 16),
                label: Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .getString('water_decrease')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: waterCount < 12
                    ? () => _updateWaterCount(waterCount + 1)
                    : null,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .getString('water_increase')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Provider.of<LocalizationService>(context, listen: false)
                          .getString('water_goal_completed_inline'),
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
    final t = s.trim().toLowerCase();
    final key = 'frequency_${t.replaceAll(' ', '_')}';
    final val = loc.getString(key);
    return val != key ? val : t;
  }

  String _localizedDosage(String s, LocalizationService loc) {
    var out = s;
    out = out.replaceAll(RegExp(r'\btablet\b', caseSensitive: false),
        loc.getString('unit_tablet'));
    out = out.replaceAll(RegExp(r'\bcapsule\b', caseSensitive: false),
        loc.getString('unit_capsule'));
    out = out.replaceAll(
        RegExp(r'\bdose\b', caseSensitive: false), loc.getString('unit_dose'));
    return out;
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    double progress = medication['completed_days'] / medication['total_days'];
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final dosageText = _localizedDosage(medication['dosage'].toString(), loc);
    final freqText =
        _localizedFrequency(medication['frequency'].toString(), loc);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medication['taken_today']
              ? Colors.green
              : const Color(0xFFE53E3E),
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
                  color: medication['taken_today']
                      ? Colors.green.withValues(alpha: 0.1)
                      : const Color(0xFFE53E3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  medication['taken_today'] ? Icons.check : Icons.medication,
                  color: medication['taken_today']
                      ? Colors.green
                      : const Color(0xFFE53E3E),
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
                    if (value &&
                        medication['completed_days'] <
                            medication['total_days']) {
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
                        .replaceFirst('{completed}',
                            medication['completed_days'].toString())
                        .replaceFirst(
                            '{total}', medication['total_days'].toString()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  medication['taken_today']
                      ? Colors.green
                      : const Color(0xFFE53E3E),
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
            Provider.of<LocalizationService>(context, listen: false)
                .getString('notification_settings_title'),
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
              border: Border.all(
                  color: isDark ? const Color(0xFF30363D) : Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule,
                      color: Color(0xFFE53E3E), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Provider.of<LocalizationService>(context, listen: false)
                            .getString('daily_motivation_time'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _dailyMotivationTime == null
                            ? '--:--'
                            : _dailyMotivationTime!.format(context),
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final loc = Provider.of<LocalizationService>(context,
                        listen: false);
                    final messenger = ScaffoldMessenger.of(context);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _dailyMotivationTime ??
                          const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) {
                      if (!mounted) return;
                      setState(() => _dailyMotivationTime = picked);
                      // Schedule via in-app notification service (simple timer loop)
                      final now = DateTime.now();
                      final first = DateTime(now.year, now.month, now.day,
                          picked.hour, picked.minute);
                      final firstTime = first.isAfter(now)
                          ? first
                          : first.add(const Duration(days: 1));
                      final quote = DailyAdviceService().getTodayQuoteText(loc);
                      // Persist selected time
                      await _preferencesService.saveCustomSettings(
                          'daily_motivation_hour', picked.hour);
                      await _preferencesService.saveCustomSettings(
                          'daily_motivation_minute', picked.minute);
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
                      final formattedTime = _formatTimeOfDay(picked);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '${loc.getString('daily_motivation_time')}: $formattedTime',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getString('edit')),
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
                border: Border.all(
                    color:
                        isDark ? const Color(0xFF30363D) : Colors.grey[300]!),
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
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600]),
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
                  content: Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getString('notification_settings_saved')),
                  backgroundColor: const Color(0xFFE53E3E),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: Text(Provider.of<LocalizationService>(context, listen: false)
                .getString('save_settings')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
      case 'test_reminders':
        return Icons.bloodtype;
      case 'critical_alerts':
        return Icons.warning;
      case 'medication_reminders':
        return Icons.medication;
      case 'nutrition_tips':
        return Icons.restaurant;
      case 'personalized_diet':
        return Icons.restaurant_menu;
      case 'motivational_messages':
        return Icons.favorite;
      case 'health_tips':
        return Icons.lightbulb;
      case 'smart_meals':
        return Icons.dining;
      case 'stress_management':
        return Icons.self_improvement;
      case 'weekly_reports':
        return Icons.star;
      case 'appointment_reminders':
        return Icons.calendar_today;
      case 'water_reminders':
        return Icons.water_drop;
      case 'exercise_reminders':
        return Icons.fitness_center;
      default:
        return Icons.notifications;
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
      SnackBar(
          content: Text(Provider.of<LocalizationService>(context, listen: false)
              .getString('notification_deleted'))),
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
            child: Text(Provider.of<LocalizationService>(context, listen: false)
                .getString('close')),
          ),
          if (!notification['isRead'])
            ElevatedButton(
              onPressed: () {
                _markAsRead(notification['id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E)),
              child: Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .getString('mark_read_long'),
                  style: const TextStyle(color: Colors.white)),
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

    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const AppDrawer(currentRoute: '/notifications'),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.5,
        surfaceTintColor: colorScheme.surface,
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                color: colorScheme.onSurface,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: colorScheme.onSurface,
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEEF2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  '$unreadCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  text: localizationService.getString('unread'),
                  icon: Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.mark_email_unread, size: 20),
                  ),
                ),
                Tab(
                  text: localizationService.getString('all'),
                  icon: const Icon(Icons.notifications, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Unread Notifications Tab - Focused and clean
          _buildUnreadNotificationsTab(isDark, localizationService, unreadCount),
          
          // All Notifications Tab
          _buildNotificationsTab(isDark, localizationService, unreadCount),
        ],
      ),
    );
  }

  void _showAddMedicationSheet() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final notesController = TextEditingController();

    String selectedFrequencyKey = 'frequency_once_daily';
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.medication_outlined,
                                color: colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.getString('add_new_medication'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.getString('med_form_description'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: loc.getString('med_name_label'),
                          prefixIcon: const Icon(Icons.label_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.getString('med_name_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dosageController,
                        decoration: InputDecoration(
                          labelText: loc.getString('dosage_hint'),
                          prefixIcon: const Icon(Icons.science_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFrequencyKey,
                        decoration: InputDecoration(
                          labelText: loc.getString('med_form_frequency_label'),
                        ),
                        items: _frequencyKeys
                            .map(
                              (key) => DropdownMenuItem<String>(
                                value: key,
                                child: Text(loc.getString(key)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            selectedFrequencyKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.access_time, color: colorScheme.primary),
                        title: Text(
                          loc.getString('med_form_time_label'),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          selectedTime.format(context),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          child: Text(loc.getString('med_form_time_button')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: loc.getString('med_form_notes_label'),
                          hintText: loc.getString('med_form_notes_hint'),
                          prefixIcon: const Icon(Icons.edit_note_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(loc.getString('cancel')),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setModalState(() => isSubmitting = true);
                                    final navigator = Navigator.of(context);
                                    final messenger =
                                        ScaffoldMessenger.of(this.context);
                                    final name = nameController.text.trim();
                                    final dosage =
                                        dosageController.text.trim().isNotEmpty
                                            ? dosageController.text.trim()
                                            : loc.getString('default_dosage');
                                    final frequency =
                                        _canonicalFrequencyFromKey(
                                            selectedFrequencyKey);
                                    final timeFormatted =
                                        _formatTimeOfDay(selectedTime);
                                    final notes = notesController.text.trim();
                                    try {
                                      await _addMedication(name, dosage,
                                          frequency, timeFormatted);
                                      if (!mounted) return;

                                      final message = loc
                                              .getString(
                                                  'medication_added_to_list')
                                              .replaceFirst('{name}', name) +
                                          (notes.isNotEmpty
                                              ? '\n${loc.getString('med_form_notes_prefix')}: $notes'
                                              : '');

                                      await _createNotification(
                                        '💊 ${loc.getString('new_medication_added')}',
                                        message,
                                        'medication_added',
                                      );

                                      if (!mounted) return;
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(loc
                                              .getString('med_added_success')),
                                          backgroundColor: colorScheme.primary,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint(
                                          'Medication add sheet error: $e');
                                      setModalState(() => isSubmitting = false);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              loc.getString('med_form_error')),
                                          backgroundColor: colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                            child: isSubmitting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(loc.getString('med_form_save')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWhyDidIGetThis(Map<String, dynamic> notification) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final pushService =
        Provider.of<push.PushNotificationService>(context, listen: false);
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
                  child: Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700])),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${value ?? loc.getString('none')}',
                      style: Theme.of(context).textTheme.bodyMedium),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                kv(loc.getString('reason_scheduled_time'),
                    reason['scheduled_time']),
                kv(loc.getString('reason_received_at'), reason['received_at']),
                kv(loc.getString('reason_repeat'), reason['repeat']),
                kv(loc.getString('reason_reminder_id'), reason['reminder_id']),
                kv(loc.getString('reason_category'), reason['category']),
                kv(loc.getString('reason_hour'), reason['hour']),
                kv(loc.getString('reason_minute'), reason['minute']),
                kv(loc.getString('reason_device_token'),
                    reason['device_token']),
                kv(loc.getString('reason_permission_granted'),
                    reason['permission_granted']),
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
