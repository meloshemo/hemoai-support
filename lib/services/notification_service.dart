import 'package:flutter/foundation.dart';
import 'dart:async';
import 'localization_service.dart';
import 'preferences_service.dart';
import 'daily_advice_service.dart';
import 'database_helper.dart';

enum NotificationType {
  reminder,
  test,
  medication,
  appointment,
  general,
}

enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
}

class NotificationItem {
  final int? id;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final NotificationType type;
  final RepeatType repeatType;
  final bool isActive;
  final DateTime createdAt;

  NotificationItem({
    this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.type,
    this.repeatType = RepeatType.none,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'type': type.index,
      'repeat_type': repeatType.index,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static NotificationItem fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduled_time']),
      type: NotificationType.values[map['type']],
      repeatType: RepeatType.values[map['repeat_type']],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  NotificationItem copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    NotificationType? type,
    RepeatType? repeatType,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      repeatType: repeatType ?? this.repeatType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];
  Timer? _checkTimer;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  
  List<NotificationItem> get activeNotifications => 
      _notifications.where((n) => n.isActive).toList();
  
  List<NotificationItem> get upcomingNotifications => 
      activeNotifications.where((n) => n.scheduledTime.isAfter(DateTime.now())).toList();
  
  List<NotificationItem> get overdueNotifications => 
      activeNotifications.where((n) => n.scheduledTime.isBefore(DateTime.now())).toList();

  void initialize() {
    _startPeriodicCheck();
    _setupWellnessScheduling();
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkNotifications();
    });
  }

  void _checkNotifications() {
    final now = DateTime.now();
    for (final notification in activeNotifications) {
      if (notification.scheduledTime.isBefore(now) || 
          notification.scheduledTime.isAtSameMomentAs(now)) {
        _triggerNotification(notification);
      }
    }
  }

  bool _wellnessScheduled = false;
  Future<void> _setupWellnessScheduling() async {
    if (_wellnessScheduled) return;
    try {
      final prefs = await PreferencesService.getInstance();
      // Gate by privacy flags
      if (!prefs.allowInAppReminders()) {
        _wellnessScheduled = true;
        return;
      }
      final settings = prefs.getNotificationSettings();
      // Water reminders
      if ((settings['water_reminders'] ?? true) == true) {
        await scheduleDailyWaterReminders();
      }
      // Daily advice at 08:00
      await scheduleDailyAdviceNotification(hour: 8, minute: 0);
      // Medication reminders from DB
      if (prefs.allowMedicationAccess()) {
        await scheduleMedicationRemindersFromDb();
      }
      _wellnessScheduled = true;
    } catch (_) {
      // swallow to avoid blocking app start
      _wellnessScheduled = true;
    }
  }

  DateTime _nextAtTodayOrTomorrow({required int hour, int minute = 0}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) return today;
    final tomorrow = today.add(const Duration(days: 1));
    return tomorrow;
  }

  Future<void> scheduleDailyAdviceNotification({required int hour, int minute = 0}) async {
    final loc = LocalizationService();
    final title = loc.getString('daily_advice_title');
    final quote = DailyAdviceService().getTodayQuoteText(loc);
    final when = _nextAtTodayOrTomorrow(hour: hour, minute: minute);
    await addNotification(NotificationItem(
      title: title,
      description: quote.isEmpty ? title : quote,
      scheduledTime: when,
      type: NotificationType.general,
      repeatType: RepeatType.daily,
    ));
  }

  Future<void> scheduleDailyWaterReminders({List<int> hours = const [9, 11, 13, 15, 17, 19]}) async {
    final loc = LocalizationService();
    final title = loc.getString('drink_water_title');
    final body = loc.getString('drink_water_body');
    for (final h in hours) {
      final when = _nextAtTodayOrTomorrow(hour: h, minute: 0);
      await addNotification(NotificationItem(
        title: title,
        description: body,
        scheduledTime: when,
        type: NotificationType.general,
        repeatType: RepeatType.daily,
      ));
    }
  }

  Future<void> scheduleMedicationRemindersFromDb() async {
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) return;
    try {
      final db = DatabaseHelper.instance;
      final meds = await db.getMedications(userId);
      final todayDate = DateTime.now();
      final todayStr = todayDate.toIso8601String().split('T')[0];
      for (final m in meds) {
        final name = (m['name'] ?? '').toString();
        if (name.isEmpty) continue;
        // Date-range filter: only schedule if active today (start_date <= today <= end_date or end_date null)
        final startStr = (m['start_date'] ?? '').toString();
        final endStr = (m['end_date'] ?? '').toString();
        DateTime? startDate = startStr.isNotEmpty ? DateTime.tryParse(startStr) : null;
        DateTime? endDate = endStr.isNotEmpty ? DateTime.tryParse(endStr) : null;
        // Normalize to date-only for comparisons
        bool withinRange = true;
        if (startDate != null) {
          final s = DateTime(startDate.year, startDate.month, startDate.day);
          final t = DateTime(todayDate.year, todayDate.month, todayDate.day);
          if (t.isBefore(s)) {
            // If start is in future, schedule first occurrence on start date instead of today
            // We'll set 'when' to start date at desired time
          }
        }
        if (endDate != null) {
          final e = DateTime(endDate.year, endDate.month, endDate.day);
          final t = DateTime(todayDate.year, todayDate.month, todayDate.day);
          if (t.isAfter(e)) {
            withinRange = false;
          }
        }
        if (!withinRange) continue;
        final timeStr = (m['time_to_take'] ?? m['time'] ?? '').toString();
        if (timeStr.isEmpty) continue;
        final parts = timeStr.split(':');
        int h = 8, mm = 0;
        if (parts.isNotEmpty) {
          h = int.tryParse(parts[0]) ?? 8;
          if (parts.length > 1) mm = int.tryParse(parts[1]) ?? 0;
        }
        DateTime when;
        if (startDate != null) {
          final t = DateTime(todayDate.year, todayDate.month, todayDate.day);
          final s = DateTime(startDate.year, startDate.month, startDate.day);
          if (t.isBefore(s)) {
            when = DateTime(s.year, s.month, s.day, h, mm);
          } else {
            when = _nextAtTodayOrTomorrow(hour: h, minute: mm);
          }
        } else {
          when = _nextAtTodayOrTomorrow(hour: h, minute: mm);
        }
        await addNotification(NotificationItem(
          title: LocalizationService().getString('medication_reminder_title') + ': ' + name,
          description: LocalizationService().getStringWithParams('medication_reminder_body', {
            'medication': name,
            'dosage_text': '',
          }),
          scheduledTime: when,
          type: NotificationType.medication,
          repeatType: RepeatType.daily,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Medication schedule error: $e');
      }
    }
  }

  void _triggerNotification(NotificationItem notification) {
    if (kDebugMode) {
      debugPrint('🔔 Reminder: ${notification.title}');
      debugPrint('📝 Description: ${notification.description}');
    }
    
    // Handle repeat notifications
    if (notification.repeatType != RepeatType.none) {
      _scheduleNextRepeat(notification);
    }
    
    notifyListeners();
  }

  void _scheduleNextRepeat(NotificationItem notification) {
    DateTime nextTime;
    switch (notification.repeatType) {
      case RepeatType.daily:
        nextTime = notification.scheduledTime.add(const Duration(days: 1));
        break;
      case RepeatType.weekly:
        nextTime = notification.scheduledTime.add(const Duration(days: 7));
        break;
      case RepeatType.monthly:
        nextTime = DateTime(
          notification.scheduledTime.year,
          notification.scheduledTime.month + 1,
          notification.scheduledTime.day,
          notification.scheduledTime.hour,
          notification.scheduledTime.minute,
        );
        break;
      case RepeatType.none:
        return;
    }

    final repeatedNotification = notification.copyWith(
      scheduledTime: nextTime,
      id: null, // New ID will be assigned
    );

    addNotification(repeatedNotification);
  }

  Future<void> addNotification(NotificationItem notification) async {
    // Ensure each notification has an ID for later toggle/delete operations
    final item = notification.id == null
        ? notification.copyWith(id: DateTime.now().millisecondsSinceEpoch)
        : notification;
    _notifications.add(item);
    notifyListeners();
  }

  // Replace the entire list (used for startup sync from persistence)
  void replaceAll(List<NotificationItem> items) {
    _notifications
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<void> removeNotification(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> toggleNotification(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isActive: !notification.isActive);
      notifyListeners();
    }
  }

  // Update scheduled time for a reminder by id
  Future<void> updateScheduledTime(int id, DateTime newTime) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(scheduledTime: newTime);
      notifyListeners();
    }
  }

  // Predefined reminder templates
  NotificationItem createMedicationReminder({
    required String medicationName,
    required DateTime time,
    RepeatType repeat = RepeatType.daily,
  }) {
    final loc = LocalizationService();
    final title = loc.getString('medication_reminder_title');
    final description = loc.getStringWithParams('medication_reminder_body', {
      'medication': medicationName,
      'dosage_text': '',
    });
    return NotificationItem(
      title: '$title: $medicationName',
      description: description,
      scheduledTime: time,
      type: NotificationType.medication,
      repeatType: repeat,
    );
  }

  NotificationItem createTestReminder({
    required String testName,
    required DateTime time,
  }) {
    final loc = LocalizationService();
    final title = loc.getString('test_reminder_title');
    final description = loc.getStringWithParams('test_reminder_body', {
      'test': testName,
      'location_text': '',
    });
    return NotificationItem(
      title: '$title: $testName',
      description: description,
      scheduledTime: time,
      type: NotificationType.test,
    );
  }

  NotificationItem createAppointmentReminder({
    required String doctorName,
    required DateTime time,
  }) {
    final loc = LocalizationService();
    final title = loc.getString('appointment_reminder_title');
    final description = loc.getStringWithParams('appointment_reminder_body', {
      'doctor': doctorName,
      'location_text': '',
    });
    return NotificationItem(
      title: '$title: Dr. $doctorName',
      description: description,
      scheduledTime: time,
      type: NotificationType.appointment,
    );
  }

  // Quick reminder methods
  void addMedicationReminder(String medication, DateTime time) {
    final reminder = createMedicationReminder(
      medicationName: medication,
      time: time,
    );
    addNotification(reminder);
  }

  void addTestReminder(String testName, DateTime time) {
    final reminder = createTestReminder(
      testName: testName,
      time: time,
    );
    addNotification(reminder);
  }

  void addAppointmentReminder(String doctorName, DateTime time) {
    final reminder = createAppointmentReminder(
      doctorName: doctorName,
      time: time,
    );
    addNotification(reminder);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  // Get all notifications
  Future<List<NotificationItem>> getAllNotifications() async {
    return List<NotificationItem>.from(_notifications);
  }

  // Statistics
  int get totalNotifications => _notifications.length;
  int get activeNotificationCount => activeNotifications.length;
  int get upcomingCount => upcomingNotifications.length;
  int get overdueCount => overdueNotifications.length;
}