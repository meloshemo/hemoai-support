import 'package:flutter/foundation.dart';
import 'dart:async';
import 'localization_service.dart';

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

  void _triggerNotification(NotificationItem notification) {
    if (kDebugMode) {
      print('🔔 Hatırlatıcı: ${notification.title}');
      print('📝 Açıklama: ${notification.description}');
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