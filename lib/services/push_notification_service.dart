import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'localization_service.dart';

// Enhanced Notification Service with Push Support
class PushNotificationService extends ChangeNotifier {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isInitialized = false;
  bool _permissionGranted = false;
  String? _deviceToken;
  Timer? _scheduleTimer;
  
  final List<ScheduledNotification> _scheduledNotifications = [];
  final List<NotificationMessage> _receivedNotifications = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  String? get deviceToken => _deviceToken;
  List<ScheduledNotification> get scheduledNotifications => List.unmodifiable(_scheduledNotifications);
  List<NotificationMessage> get receivedNotifications => List.unmodifiable(_receivedNotifications);

  // Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _requestPermissions();
      await _configureNotifications();
      _startScheduleChecker();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ PushNotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize PushNotificationService: $e');
      }
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web notification permission
      try {
        _permissionGranted = true; // Simulated for web
        if (kDebugMode) {
          print('📱 Web notification permission granted (simulated)');
        }
      } catch (e) {
        _permissionGranted = false;
        if (kDebugMode) {
          print('❌ Web notification permission denied: $e');
        }
      }
    } else {
      // Mobile notification permission (would use flutter_local_notifications)
      _permissionGranted = true; // Simulated for now
      if (kDebugMode) {
        print('📱 Mobile notification permission granted (simulated)');
      }
    }
  }

  // Configure notification handling
  Future<void> _configureNotifications() async {
    if (kIsWeb) {
      // Web-specific configuration
      _deviceToken = 'web_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      // Mobile-specific configuration
      _deviceToken = 'mobile_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    if (kDebugMode) {
      print('🔑 Device token: $_deviceToken');
    }
  }

  // Start checking for scheduled notifications
  void _startScheduleChecker() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkScheduledNotifications();
    });
  }

  // Check and trigger scheduled notifications
  void _checkScheduledNotifications() {
    final now = DateTime.now();
    final toTrigger = _scheduledNotifications.where((notification) {
      return notification.scheduledTime.isBefore(now) || 
             notification.scheduledTime.isAtSameMomentAs(now);
    }).toList();

    for (final notification in toTrigger) {
      _triggerNotification(notification);
      _scheduledNotifications.remove(notification);
    }

    if (toTrigger.isNotEmpty) {
      notifyListeners();
    }
  }

  // Trigger a notification
  void _triggerNotification(ScheduledNotification notification) {
    final message = NotificationMessage(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      data: notification.data,
      receivedAt: DateTime.now(),
      type: notification.type,
    );

    _receivedNotifications.insert(0, message);
    
    // Show system notification
    _showSystemNotification(message);
    
    if (kDebugMode) {
      print('🔔 Notification triggered: ${message.title}');
    }

    // Auto-reschedule daily motivation notifications for the next day
    try {
      final repeat = message.data['repeat'];
      if (repeat == 'daily_motivation') {
        final int hour = (message.data['hour'] is String)
            ? int.tryParse(message.data['hour']) ?? DateTime.now().hour
            : (message.data['hour'] as int? ?? DateTime.now().hour);
        final int minute = (message.data['minute'] is String)
            ? int.tryParse(message.data['minute']) ?? DateTime.now().minute
            : (message.data['minute'] as int? ?? DateTime.now().minute);
        final String? quote = message.data['quote'] as String?;
        // Schedule for next day at the same time
        final now = DateTime.now();
        final next = DateTime(now.year, now.month, now.day, hour, minute).add(const Duration(days: 1));
        final loc = LocalizationService();
        final title = loc.getString('motivational_rotating_title');
        final body = quote != null && quote.trim().isNotEmpty
            ? quote
            : loc.getString('motivational_message_long');
        scheduleNotification(
          title: title,
          body: body,
          scheduledTime: next,
          type: NotificationType.general,
          data: {
            'repeat': 'daily_motivation',
            'hour': hour,
            'minute': minute,
            if (quote != null) 'quote': quote,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Auto-reschedule daily motivation failed: $e');
      }
    }

    notifyListeners();
  }

  // Show system notification
  void _showSystemNotification(NotificationMessage message) {
    if (kIsWeb) {
      _showWebNotification(message);
    } else {
      _showMobileNotification(message);
    }
  }

  // Schedule daily motivational notification at specific time
  Future<String> scheduleDailyMotivation({
    required int hour,
    required int minute,
    String? quote,
  }) async {
    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final loc = LocalizationService();
    final title = loc.getString('motivational_rotating_title');
    final body = (quote != null && quote.trim().isNotEmpty)
        ? quote
        : loc.getString('motivational_message_long');

    return await scheduleNotification(
      title: title,
      body: body,
      scheduledTime: scheduled,
      type: NotificationType.general,
      data: {
        'repeat': 'daily_motivation',
        'hour': hour,
        'minute': minute,
        if (quote != null) 'quote': quote,
      },
    );
  }

  // Web notification
  void _showWebNotification(NotificationMessage message) {
    if (kDebugMode) {
      print('🌐 Web notification: ${message.title} - ${message.body}');
    }
    // In a real implementation, you would use js interop for web notifications
  }

  // Mobile notification
  void _showMobileNotification(NotificationMessage message) {
    if (kDebugMode) {
      print('📱 Mobile notification: ${message.title} - ${message.body}');
    }
    // In a real implementation, you would use flutter_local_notifications
  }

  // Schedule a notification
  Future<String> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
    NotificationType type = NotificationType.general,
  }) async {
    final id = 'notification_${DateTime.now().millisecondsSinceEpoch}';
    
    final notification = ScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      data: data ?? {},
      type: type,
    );

    _scheduledNotifications.add(notification);
    _scheduledNotifications.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    
    notifyListeners();
    
    if (kDebugMode) {
      print('⏰ Notification scheduled: $title for ${scheduledTime.toString()}');
    }

    return id;
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(String id) async {
    _scheduledNotifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
    
    if (kDebugMode) {
      print('❌ Notification cancelled: $id');
    }
  }

  // Schedule medication reminder
  Future<String> scheduleMedicationReminder({
    required String medicationName,
    required DateTime scheduleTime,
    String? dosage,
  }) async {
    final loc = LocalizationService();
    final title = loc.getString('medication_reminder_title');
    final dosageText = dosage != null && dosage.trim().isNotEmpty ? ' (${dosage.trim()})' : '';
    final body = loc.getStringWithParams('medication_reminder_body', {
      'medication': medicationName,
      'dosage_text': dosageText,
    });

    return await scheduleNotification(
      title: title,
      body: body,
      scheduledTime: scheduleTime,
      type: NotificationType.medication,
      data: {
        'medication': medicationName,
        'dosage': dosage,
        'type': 'medication_reminder',
      },
    );
  }

  // Schedule appointment reminder
  Future<String> scheduleAppointmentReminder({
    required String doctorName,
    required DateTime appointmentTime,
    String? location,
  }) async {
    final loc = LocalizationService();
    final title = loc.getString('appointment_reminder_title');
    final locationText = location != null && location.trim().isNotEmpty ? ' (${location.trim()})' : '';
    final body = loc.getStringWithParams('appointment_reminder_body', {
      'doctor': doctorName,
      'location_text': locationText,
    });

    return await scheduleNotification(
      title: title,
      body: body,
      scheduledTime: appointmentTime.subtract(const Duration(hours: 1)), // 1 hour before
      type: NotificationType.appointment,
      data: {
        'doctor': doctorName,
        'location': location,
        'appointment_time': appointmentTime.toIso8601String(),
        'type': 'appointment_reminder',
      },
    );
  }

  // Schedule test reminder
  Future<String> scheduleTestReminder({
    required String testName,
    required DateTime testTime,
    String? location,
  }) async {
    final loc = LocalizationService();
    final title = loc.getString('test_reminder_title');
    final locationText = location != null && location.trim().isNotEmpty ? ' (${location.trim()})' : '';
    final body = loc.getStringWithParams('test_reminder_body', {
      'test': testName,
      'location_text': locationText,
    });

    return await scheduleNotification(
      title: title,
      body: body,
      scheduledTime: testTime.subtract(const Duration(hours: 2)), // 2 hours before
      type: NotificationType.test,
      data: {
        'test_name': testName,
        'location': location,
        'test_time': testTime.toIso8601String(),
        'type': 'test_reminder',
      },
    );
  }

  // Mark notification as read
  void markAsRead(String id) {
    final index = _receivedNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _receivedNotifications[index] = _receivedNotifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Clear all notifications
  void clearAllNotifications() {
    _receivedNotifications.clear();
    notifyListeners();
  }

  // Get unread count
  int get unreadCount => _receivedNotifications.where((n) => !n.isRead).length;

  // Dispose
  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }
}

// Scheduled Notification Model
class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final Map<String, dynamic> data;
  final NotificationType type;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.data,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'data': jsonEncode(data),
      'type': type.index,
    };
  }

  factory ScheduledNotification.fromMap(Map<String, dynamic> map) {
    return ScheduledNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduled_time']),
      data: jsonDecode(map['data']),
      type: NotificationType.values[map['type']],
    );
  }
}

// Notification Message Model
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final NotificationType type;
  final bool isRead;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    required this.type,
    this.isRead = false,
  });

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      receivedAt: receivedAt ?? this.receivedAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': jsonEncode(data),
      'received_at': receivedAt.millisecondsSinceEpoch,
      'type': type.index,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory NotificationMessage.fromMap(Map<String, dynamic> map) {
    return NotificationMessage(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      data: jsonDecode(map['data']),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(map['received_at']),
      type: NotificationType.values[map['type']],
      isRead: map['is_read'] == 1,
    );
  }
}

// Notification Types (enhanced)
enum NotificationType {
  general,
  medication,
  appointment,
  test,
  reminder,
  healthAlert,
  system,
}