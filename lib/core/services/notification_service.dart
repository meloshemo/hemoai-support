import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:logger/logger.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();
  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Initialize notifications plugin
      _notifications = FlutterLocalNotificationsPlugin();
      
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Initialize plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      _logger.i('Notification service initialized successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize notification service: $e', 
                error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      _logger.e('Failed to request notification permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');
    // Handle notification tap
    // You can navigate to specific screens based on the payload
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool repeatDaily = false,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final androidDetails = AndroidNotificationDetails(
        'hemoai_reminders',
        'HemoAI Reminders',
        channelDescription: 'Notifications for health reminders and appointments',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (repeatDaily) {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      _logger.i('Reminder scheduled: $title at $scheduledTime');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to schedule reminder: $e', 
                error: e, stackTrace: stackTrace);
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _notifications.cancel(id);
      _logger.i('Reminder cancelled: $id');
    } catch (e) {
      _logger.e('Failed to cancel reminder: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      _logger.i('All reminders cancelled');
    } catch (e) {
      _logger.e('Failed to cancel all reminders: $e');
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'hemoai_instant',
        'HemoAI Instant',
        channelDescription: 'Instant notifications from HemoAI',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      _logger.i('Instant notification shown: $title');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to show instant notification: $e', 
                error: e, stackTrace: stackTrace);
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      _logger.e('Failed to get pending notifications: $e');
      return [];
    }
  }

  Future<void> scheduleHealthReminders(UserModel user) async {
    try {
      // Schedule daily health check reminder
      await scheduleReminder(
        id: 1000 + user.id,
        title: 'Daily Health Check',
        body: 'Time for your daily health check-in, ${user.name}!',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        repeatDaily: true,
        payload: 'daily_health_check',
      );

      // Schedule weekly test reminder
      await scheduleReminder(
        id: 2000 + user.id,
        title: 'Weekly Test Reminder',
        body: 'Don\'t forget to update your health metrics this week!',
        scheduledTime: DateTime.now().add(const Duration(days: 7)),
        payload: 'weekly_test_reminder',
      );

      _logger.i('Health reminders scheduled for user: ${user.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to schedule health reminders: $e', 
                error: e, stackTrace: stackTrace);
    }
  }

  Future<void> scheduleMedicationReminder({
    required int userId,
    required String medicationName,
    required DateTime time,
    required bool repeatDaily,
  }) async {
    try {
      await scheduleReminder(
        id: 3000 + userId + time.hour,
        title: 'Medication Reminder',
        body: 'Time to take $medicationName',
        scheduledTime: time,
        repeatDaily: repeatDaily,
        payload: 'medication_reminder',
      );

      _logger.i('Medication reminder scheduled: $medicationName at $time');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to schedule medication reminder: $e', 
                error: e, stackTrace: stackTrace);
    }
  }

  Future<void> scheduleTestReminder({
    required int userId,
    required String testType,
    required DateTime scheduledTime,
  }) async {
    try {
      await scheduleReminder(
        id: 4000 + userId,
        title: 'Test Appointment',
        body: 'You have a $testType appointment scheduled',
        scheduledTime: scheduledTime,
        payload: 'test_appointment',
      );

      _logger.i('Test reminder scheduled: $testType at $scheduledTime');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to schedule test reminder: $e', 
                error: e, stackTrace: stackTrace);
    }
  }
}
