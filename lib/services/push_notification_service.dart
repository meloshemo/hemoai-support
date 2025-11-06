import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'localization_service.dart';
import 'daily_advice_service.dart';
import 'preferences_service.dart';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // In-memory debug log (for Notification Debug screen)
  final List<NotificationLogEntry> _debugLogs = [];
  // Mapping between reminders and scheduled notifications
  final Map<int, Set<String>> _reminderSchedules = {};
  final Map<String, int> _scheduleToReminder = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  String? get deviceToken => _deviceToken;
  List<ScheduledNotification> get scheduledNotifications => List.unmodifiable(_scheduledNotifications);
  List<NotificationMessage> get receivedNotifications => List.unmodifiable(_receivedNotifications);
  List<NotificationLogEntry> get debugLogs => List.unmodifiable(_debugLogs);

  void _log(String message) {
    // keep last 300 entries
    _debugLogs.add(NotificationLogEntry(DateTime.now(), message));
    if (_debugLogs.length > 300) {
      _debugLogs.removeRange(0, _debugLogs.length - 300);
    }
    // Notify listeners so debug UI can update
    notifyListeners();
  }

  // Safely coerce dynamic to int
  int? _coerceInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
    return null;
  }

  // Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _requestPermissions();
      await _configureNotifications();
      await _rehydrateSchedules();
      _startScheduleChecker();
      _isInitialized = true;
      
      if (kDebugMode) {
  debugPrint('✅ PushNotificationService initialized successfully');
        _log('Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
  debugPrint('❌ Failed to initialize PushNotificationService: $e');
        _log('Init failed: $e');
      }
    }
  }

  // Public permission request for settings UI
  Future<void> requestPermissions() async {
    await _requestPermissions();
    notifyListeners();
  }

  // Open system app notification settings
  Future<void> openSystemSettings() async {
    try {
      await openAppSettings();
    } catch (_) {
      // no-op
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web notification permission
      try {
        _permissionGranted = true; // Simulated for web
        if (kDebugMode) {
          debugPrint('📱 Web notification permission granted (simulated)');
        }
        _log('Permission granted (web simulated)');
      } catch (e) {
        _permissionGranted = false;
        if (kDebugMode) {
          debugPrint('❌ Web notification permission denied: $e');
        }
        _log('Permission denied (web): $e');
      }
    } else {
      // Mobile notification permission (Android 13+/iOS/macOS)
      try {
        final status = await Permission.notification.status;
        if (status.isGranted) {
          _permissionGranted = true;
          if (kDebugMode) {
            debugPrint('📱 Notification permission already granted');
          }
          _log('Permission granted (already)');
          return;
        }

        // Request permission
        final req = await Permission.notification.request();
        _permissionGranted = req.isGranted;

        if (_permissionGranted) {
          if (kDebugMode) {
            debugPrint('📱 Notification permission granted (request)');
          }
          _log('Permission granted (request)');
        } else if (req.isPermanentlyDenied) {
          if (kDebugMode) {
            debugPrint('⚠️ Notification permission permanently denied');
          }
          _log('Permission permanently denied');
        } else {
          if (kDebugMode) {
            debugPrint('❌ Notification permission denied');
          }
          _log('Permission denied');
        }
      } catch (e) {
        // In tests or unsupported environments, avoid blocking flows
        _permissionGranted = true; // fallback to previous simulated behavior
        if (kDebugMode) {
          debugPrint('⚠️ Permission request failed, falling back to simulated grant: $e');
        }
        _log('Permission request failed, using simulated grant: $e');
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
  debugPrint('🔑 Device token: $_deviceToken');
    }
    _log('Device token set: $_deviceToken');
  }

  // Start checking for scheduled notifications
  void _startScheduleChecker() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkScheduledNotifications();
    });
  }

  // Persist schedules to local storage (shared_prefs JSON)
  Future<void> _persistSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _scheduledNotifications.map((e) => e.toMap()).toList();
      await prefs.setString('scheduled_notifications_v1', jsonEncode(list));
    } catch (e) {
      _log('Persist schedules failed: $e');
    }
  }

  Future<void> _rehydrateSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('scheduled_notifications_v1');
      if (s == null || s.isEmpty) return;
      final List<dynamic> arr = jsonDecode(s);
      final list = arr.cast<Map<String, dynamic>>().map(ScheduledNotification.fromMap).toList();
      _scheduledNotifications
        ..clear()
        ..addAll(list);
      _scheduledNotifications.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      _log('Rehydrated ${list.length} scheduled notifications');
      notifyListeners();
    } catch (e) {
      _log('Rehydrate schedules failed: $e');
    }
  }

  // Check and trigger scheduled notifications
  void _checkScheduledNotifications() {
    final now = DateTime.now();
    final toTrigger = _scheduledNotifications.where((notification) {
      return notification.scheduledTime.isBefore(now) || 
             notification.scheduledTime.isAtSameMomentAs(now);
    }).toList();

    try {
      for (final notification in toTrigger) {
        try {
          _triggerNotification(notification);
          _scheduledNotifications.remove(notification);
          _log('Notification triggered successfully: ${notification.id}');
        } catch (e) {
          _log('Error triggering notification ${notification.id}: $e');
          // Keep the notification for retry, but mark it as failed
          notification.metadata['last_error'] = e.toString();
          notification.metadata['error_count'] = (notification.metadata['error_count'] ?? 0) + 1;
          
          // Remove after 3 failed attempts
          if ((notification.metadata['error_count'] as int) >= 3) {
            _scheduledNotifications.remove(notification);
            _log('Notification ${notification.id} removed after 3 failed attempts');
          }
        }
      }
      if (toTrigger.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      _log('Critical error in notification checker: $e');
    }
  }

  // Trigger a notification
  void _triggerNotification(ScheduledNotification notification) {
    // Drop mapping for this schedule id if any
    final rid = _scheduleToReminder.remove(notification.id);
    if (rid != null) {
      final set = _reminderSchedules[rid];
      set?.remove(notification.id);
      if (set != null && set.isEmpty) {
        _reminderSchedules.remove(rid);
      }
    }
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
  debugPrint('🔔 Notification triggered: ${message.title}');
    }
    _log('Triggered: ${message.title} (${message.id})');

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
        // Schedule for next day at the same time
        final now = DateTime.now();
        final next = DateTime(now.year, now.month, now.day, hour, minute).add(const Duration(days: 1));
        final loc = LocalizationService();
        final title = loc.getString('motivational_rotating_title');
        // Fresh quote for next day
        final body = DailyAdviceService().getQuoteForDate(loc, next);
        scheduleNotification(
          title: title,
          body: body,
          scheduledTime: next,
          type: NotificationType.general,
          data: {
            'repeat': 'daily_motivation',
            'hour': hour,
            'minute': minute,
          },
        );
      } else if (repeat == 'daily' || repeat == 'weekly' || repeat == 'monthly') {
        final int hour = (message.data['hour'] is String)
            ? int.tryParse(message.data['hour']) ?? DateTime.now().hour
            : (message.data['hour'] as int? ?? DateTime.now().hour);
        final int minute = (message.data['minute'] is String)
            ? int.tryParse(message.data['minute']) ?? DateTime.now().minute
            : (message.data['minute'] as int? ?? DateTime.now().minute);
        final now = DateTime.now();
        DateTime next = DateTime(now.year, now.month, now.day, hour, minute);
        if (repeat == 'daily') {
          next = next.add(const Duration(days: 1));
        } else if (repeat == 'weekly') {
          next = next.add(const Duration(days: 7));
        } else if (repeat == 'monthly') {
          next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
        }
        // Schedule same title/body/type from message
        scheduleNotification(
          title: message.title,
          body: message.body,
          scheduledTime: next,
          type: message.type,
          data: {
            ...message.data,
            'hour': hour,
            'minute': minute,
          },
        );
  _log('Auto-rescheduled ($repeat) for ${next.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
  debugPrint('⚠️ Auto-reschedule daily motivation failed: $e');
      }
      _log('Auto-reschedule failed: $e');
    }

    // Update persisted schedules after modifications
    _persistSchedules();
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

  // Reason/metadata for "Why did I get this?" detail view
  Map<String, Object?> getNotificationReason(String id) {
    final scheduled = _scheduledNotifications.firstWhere(
      (n) => n.id == id,
      orElse: () => ScheduledNotification(
        id: id,
        title: '',
        body: '',
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(0),
        data: const {},
        type: NotificationType.general,
      ),
    );
    final received = _receivedNotifications.firstWhere(
      (m) => m.id == id,
      orElse: () => NotificationMessage(
        id: id,
        title: '',
        body: '',
        data: const {},
        receivedAt: DateTime.fromMillisecondsSinceEpoch(0),
        type: NotificationType.general,
      ),
    );
    return {
      'scheduled_time': scheduled.scheduledTime.toIso8601String(),
      'received_at': received.receivedAt.toIso8601String(),
      'repeat': received.data['repeat'] ?? scheduled.data['repeat'] ?? 'none',
      'reminder_id': received.data['reminder_id'] ?? scheduled.data['reminder_id'],
      'category': received.data['category'] ?? scheduled.data['category'],
      'hour': received.data['hour'] ?? scheduled.data['hour'],
      'minute': received.data['minute'] ?? scheduled.data['minute'],
      'device_token': _deviceToken,
      'permission_granted': _permissionGranted,
    };
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
  // Prefer provided quote; else pick deterministic quote for the scheduled day
  final body = (quote != null && quote.trim().isNotEmpty)
    ? quote
    : DailyAdviceService().getQuoteForDate(loc, scheduled);

    return await scheduleNotification(
      title: title,
      body: body,
      scheduledTime: scheduled,
      type: NotificationType.general,
      data: {
        'repeat': 'daily_motivation',
        'hour': hour,
        'minute': minute,
      },
    );
  }

  // Schedule a daily diet reminder at a chosen time
  Future<String> scheduleDailyDietReminder({
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final loc = LocalizationService();
    final title = loc.getString('diet_program');
    final body = loc.getString('weekly_plan');
    return await scheduleNotification(
      title: title,
      body: body,
      scheduledTime: scheduled,
      type: NotificationType.general,
      data: {
        'repeat': 'daily',
        'category': 'diet',
        'hour': hour,
        'minute': minute,
      },
    );
  }

  // Schedule weekly diet reminders for 7 days at the same time
  // dayTitles: label of the day (localized) to show; planTitles: diet program title per day
  Future<List<String>> scheduleWeeklyDietReminders({
    required int hour,
    required int minute,
    required List<String> dayTitles, // length 7, starting Sunday
    required List<String> planTitles, // length 7
  }) async {
    assert(dayTitles.length == 7 && planTitles.length == 7);
    final now = DateTime.now();
    final List<String> ids = [];
    for (int i = 0; i < 7; i++) {
      // 0=Sun..6=Sat; compute next occurrence of that weekday at hour:minute
      final int targetWeekday = (i == 0) ? DateTime.sunday : i; // 1=Mon..7=Sun
      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      int deltaDays = (targetWeekday - now.weekday) % 7;
      if (deltaDays < 0) deltaDays += 7;
      scheduled = scheduled.add(Duration(days: deltaDays));
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 7));

      final id = await scheduleNotification(
        title: dayTitles[i],
        body: planTitles[i],
        scheduledTime: scheduled,
        type: NotificationType.general,
        data: {
          'repeat': 'weekly',
          'category': 'diet',
          'hour': hour,
          'minute': minute,
          'weekdayIndex0Sun': i,
        },
      );
      ids.add(id);
    }
    return ids;
  }

  // Web notification
  void _showWebNotification(NotificationMessage message) {
    if (kDebugMode) {
  debugPrint('🌐 Web notification: ${message.title} - ${message.body}');
    }
    _log('Show web notification: ${message.title}');
    // In a real implementation, you would use js interop for web notifications
  }

  // Mobile notification
  void _showMobileNotification(NotificationMessage message) {
    if (kDebugMode) {
  debugPrint('📱 Mobile notification: ${message.title} - ${message.body}');
    }
    _log('Show mobile notification: ${message.title}');
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
    try {
      // Validate readiness and permissions
      if (!_isInitialized) {
        // Attempt lazy init once
        try { await initialize(); } catch (_) {}
      }
      if (!_permissionGranted) {
        _log('Schedule blocked: permission not granted');
        throw Exception('notification_permission_denied');
      }

      // Normalize times in the past to a near-future time to avoid immediate flood
      final now = DateTime.now();
      DateTime targetTime = scheduledTime;
      if (!targetTime.isAfter(now)) {
        targetTime = now.add(const Duration(seconds: 5));
        _log('Adjusted past scheduledTime to ${targetTime.toIso8601String()}');
      }

      // Prepare and sanitize data
      final Map<String, dynamic> payload = {...(data ?? {})};
      final repeat = payload['repeat'];
      // Ensure hour/minute present for repeatable notifications to enable auto-reschedule
      if (repeat == 'daily' || repeat == 'weekly' || repeat == 'monthly' || repeat == 'daily_motivation') {
        payload['hour'] = _coerceInt(payload['hour']) ?? targetTime.hour;
        payload['minute'] = _coerceInt(payload['minute']) ?? targetTime.minute;
      }

      final id = 'notification_${DateTime.now().millisecondsSinceEpoch}';
      final notification = ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: targetTime,
        data: payload,
        type: type,
      );

      _scheduledNotifications.add(notification);
      _scheduledNotifications.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      // If linked to a reminder, register mapping
      final reminderIdRaw = notification.data['reminder_id'];
      int? reminderId;
      if (reminderIdRaw is int) {
        reminderId = reminderIdRaw;
      } else if (reminderIdRaw is String) {
        reminderId = int.tryParse(reminderIdRaw);
      }
      if (reminderId != null) {
        _scheduleToReminder[id] = reminderId;
        _reminderSchedules.putIfAbsent(reminderId, () => <String>{}).add(id);
      }

      notifyListeners();
  await _persistSchedules();
      if (kDebugMode) {
        debugPrint('⏰ Notification scheduled: $title for ${targetTime.toString()}');
      }
      _log('Scheduled: $title at ${targetTime.toIso8601String()} (id=$id)');

      return id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ scheduleNotification failed: $e');
      }
      _log('Schedule failed: $e');
      rethrow;
    }
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(String id) async {
    try {
      final before = _scheduledNotifications.length;
      _scheduledNotifications.removeWhere((notification) => notification.id == id);
      final removed = before != _scheduledNotifications.length;
      // Clean mapping
      final rid = _scheduleToReminder.remove(id);
      if (rid != null) {
        final set = _reminderSchedules[rid];
        set?.remove(id);
        if (set != null && set.isEmpty) {
          _reminderSchedules.remove(rid);
        }
      }
      notifyListeners();
      await _persistSchedules();
      if (kDebugMode) {
        debugPrint('❌ Notification cancelled: $id');
      }
      _log('Cancelled: $id');
      if (!removed) {
        _log('Cancel note: id not found in schedule list');
      }
    } catch (e) {
      _log('Cancel failed for $id: $e');
      rethrow;
    }
  }

  // Action: user marked medication/test/reminder as taken/completed
  Future<void> actionMarkTaken(NotificationMessage message) async {
    try {
      final rid = _coerceInt(message.data['reminder_id']);
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      // Log action
      await DatabaseHelper.instance.insertReminderLog(
        reminderId: rid ?? -1,
        userId: userId,
        action: 'taken',
        actionDate: DateTime.now(),
        scheduledTime: null,
        metadata: jsonEncode({'notification_id': message.id}),
      );
      // Update streaks if reminder_id valid
      if (rid != null && rid >= 0) {
        final streak = await DatabaseHelper.instance.getReminderStreak(rid, userId: userId);
        final last = streak['last_completed_date'] as String?;
        final today = DateTime.now();
        final todayStr = today.toIso8601String().split('T').first;
        int current = (streak['current_streak'] as int?) ?? 0;
        int longest = (streak['longest_streak'] as int?) ?? 0;
        if (last == null) {
          current = 1;
        } else {
          final lastDate = DateTime.tryParse(last);
          if (lastDate != null) {
            final diffDays = today.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
            if (diffDays == 0) {
              // already counted today; keep as-is
            } else if (diffDays == 1) {
              current += 1;
            } else {
              current = 1;
            }
          } else {
            current = 1;
          }
        }
        if (current > longest) longest = current;
        await DatabaseHelper.instance.upsertReminderStreak(
          reminderId: rid,
          userId: userId,
          currentStreak: current,
          longestStreak: longest,
          lastCompletedDate: todayStr,
        );
      }
      _log('Action taken recorded for ${message.id} (rid=${rid ?? 'n/a'})');
    } catch (e) {
      _log('Action taken failed: $e');
    }
  }

  // Action: snooze notification and log it
  Future<String?> actionSnooze(NotificationMessage message, {int minutes = 10}) async {
    try {
      final rid = _coerceInt(message.data['reminder_id']);
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      await DatabaseHelper.instance.insertReminderLog(
        reminderId: rid ?? -1,
        userId: userId,
        action: 'snooze',
        actionDate: DateTime.now(),
        scheduledTime: null,
        metadata: jsonEncode({'minutes': minutes, 'notification_id': message.id}),
      );
      final id = await snoozeReceived(message: message, delay: Duration(minutes: minutes));
      return id;
    } catch (e) {
      _log('Action snooze failed: $e');
      return null;
    }
  }

  // Handle notification tap (deep link helper)
  String? handleTap(NotificationMessage message) {
    try {
      final deeplink = message.data['deeplink'];
      _log('Tap handled. deeplink=$deeplink');
      return deeplink is String ? deeplink : null;
    } catch (e) {
      _log('Tap handle failed: $e');
      return null;
    }
  }

  // Snooze a received notification by scheduling it again after a delay
  Future<String> snoozeReceived({
    required NotificationMessage message,
    required Duration delay,
  }) async {
    try {
      final DateTime scheduledTime = DateTime.now().add(delay);
      final minutes = delay.inMinutes;
      // preserve mapping if any
      final data = {
        ...message.data,
        'repeat': 'none',
        'snoozed_minutes': minutes,
        'source': 'snooze_received',
      };
      final id = await scheduleNotification(
        title: message.title,
        body: message.body,
        scheduledTime: scheduledTime,
        type: message.type,
        data: data,
      );
      if (kDebugMode) {
        debugPrint('😴 Snoozed received notification ${message.id} for $minutes minutes -> $id');
      }
      _log('Snoozed received ${message.id} by ${minutes}m -> $id');
      return id;
    } catch (e) {
      _log('Snooze (received) failed: $e');
      rethrow;
    }
  }

  // Snooze an existing scheduled notification by replacing it with a new one at a later time
  Future<String> snoozeScheduled({
    required ScheduledNotification scheduled,
    required Duration delay,
  }) async {
    try {
      // remove original
      await cancelNotification(scheduled.id);
      final DateTime newTime = DateTime.now().add(delay);
      final minutes = delay.inMinutes;
      final newData = {
        ...scheduled.data,
        'repeat': 'none',
        'snoozed_minutes': minutes,
        'source': 'snooze_scheduled',
      };
      final id = await scheduleNotification(
        title: scheduled.title,
        body: scheduled.body,
        scheduledTime: newTime,
        type: scheduled.type,
        data: newData,
      );
      if (kDebugMode) {
        debugPrint('😴 Snoozed scheduled notification ${scheduled.id} for $minutes minutes -> $id');
      }
      _log('Snoozed scheduled ${scheduled.id} by ${minutes}m -> $id');
      return id;
    } catch (e) {
      _log('Snooze (scheduled) failed: $e');
      rethrow;
    }
  }

  // Dismiss notification for today (cancel today's occurrence, reschedule for tomorrow if repeating)
  Future<void> dismissForToday({
    NotificationMessage? received,
    ScheduledNotification? scheduled,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      if (received != null) {
        // For received notifications, check if it's repeating
        final repeat = received.data['repeat'];
        if (repeat == 'daily' || repeat == 'weekly' || repeat == 'monthly' || repeat == 'daily_motivation') {
          // Reschedule for tomorrow at the same time
          final hour = _coerceInt(received.data['hour']) ?? 9;
          final minute = _coerceInt(received.data['minute']) ?? 0;
          final nextTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
          
          await scheduleNotification(
            title: received.title,
            body: received.body,
            scheduledTime: nextTime,
            type: received.type,
            data: {
              ...received.data,
              'dismissed_today': true,
              'dismissed_date': today.toIso8601String(),
            },
          );
          _log('Dismissed received ${received.id} for today, rescheduled for tomorrow');
        } else {
          // Non-repeating, just cancel
          _log('Dismissed non-repeating received ${received.id} for today');
        }
      } else if (scheduled != null) {
        // Cancel the scheduled notification
        await cancelNotification(scheduled.id);
        
        // Check if it's repeating
        final repeat = scheduled.data['repeat'];
        if (repeat == 'daily' || repeat == 'weekly' || repeat == 'monthly' || repeat == 'daily_motivation') {
          // Reschedule for tomorrow at the same time
          final hour = _coerceInt(scheduled.data['hour']) ?? scheduled.scheduledTime.hour;
          final minute = _coerceInt(scheduled.data['minute']) ?? scheduled.scheduledTime.minute;
          final nextTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
          
          await scheduleNotification(
            title: scheduled.title,
            body: scheduled.body,
            scheduledTime: nextTime,
            type: scheduled.type,
            data: {
              ...scheduled.data,
              'dismissed_today': true,
              'dismissed_date': today.toIso8601String(),
            },
          );
          _log('Dismissed scheduled ${scheduled.id} for today, rescheduled for tomorrow');
        } else {
          _log('Dismissed non-repeating scheduled ${scheduled.id} for today');
        }
      }
    } catch (e) {
      _log('Dismiss for today failed: $e');
      rethrow;
    }
  }

  // Cancel all scheduled notifications for a given reminder id
  Future<void> cancelSchedulesForReminder(int reminderId) async {
    final ids = _reminderSchedules.remove(reminderId)?.toList() ?? const <String>[];
    for (final id in ids) {
      _scheduleToReminder.remove(id);
      _scheduledNotifications.removeWhere((n) => n.id == id);
    }
    if (ids.isNotEmpty) notifyListeners();
    if (kDebugMode) {
  debugPrint('❌ Cancelled ${ids.length} schedules for reminder $reminderId');
    }
    _log('Cancelled ${ids.length} schedules for reminder $reminderId');
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
      _log('Marked as read: $id');
    }
  }

  // Clear all notifications
  void clearAllNotifications() {
    _receivedNotifications.clear();
    notifyListeners();
    _log('Cleared all received notifications');
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

class NotificationLogEntry {
  final DateTime timestamp;
  final String message;
  NotificationLogEntry(this.timestamp, this.message);
}

// Scheduled Notification Model
class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final Map<String, dynamic> data;
  final NotificationType type;
  // runtime metadata for retries, diagnostics (not persisted in toMap)
  final Map<String, dynamic> metadata;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.data,
    required this.type,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.from(metadata ?? {});

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
      metadata: {},
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