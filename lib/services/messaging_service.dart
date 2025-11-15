import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemoai/config/environment.dart';

import 'preferences_service.dart';

/// MessagingService
/// - Handles FCM permission, token refresh, basic topic/device registration
/// - Stores the token per user under Firestore users/{uid}/devices/{token}
class MessagingService extends ChangeNotifier {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final _messaging = FirebaseMessaging.instance;
  String? _token;
  bool _initialized = false;
  bool get isInitialized => _initialized;
  String? get token => _token;

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Attempt web push setup if VAPID key provided and service worker expected.
      try {
        // Request notification permission
        final permission = await _messaging.requestPermission();
        if (permission.authorizationStatus == AuthorizationStatus.authorized ||
            permission.authorizationStatus == AuthorizationStatus.provisional) {
          // Use Env.webVapidKey when defined (pass via --dart-define)
          // ignore: unnecessary_null_comparison
          final vapidKey = Env.webVapidKey.isEmpty ? null : Env.webVapidKey;
          _token = await _messaging.getToken(vapidKey: vapidKey);
          notifyListeners();
          // Ensure auth and register token mapping for web as well
          if (FirebaseAuth.instance.currentUser == null) {
            try { await FirebaseAuth.instance.signInAnonymously(); } catch (_) {}
          }
          await _registerToken();
        }
      } catch (e) {
        debugPrint('[FCM Web] Setup skipped: $e');
      }
      _initialized = true;
      return;
    }

    // iOS: request permissions
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    // Ensure auth for Firestore mapping
    if (FirebaseAuth.instance.currentUser == null) {
      try { await FirebaseAuth.instance.signInAnonymously(); } catch (_) {}
    }

    // Get token and subscribe to refresh
    try {
      _token = await _messaging.getToken();
      notifyListeners();
      await _registerToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        _token = t;
        notifyListeners();
        await _registerToken();
      });
    } catch (_) {}

    // Foreground handler: simple debug log (extend as needed)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
    });

    _initialized = true;
  }

  Future<void> _registerToken() async {
    final t = _token;
    if (t == null || t.isEmpty) return;
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) return;
    final uid = userId.toString();

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(t);
    await doc.set({
      'token': t,
      'platform': kIsWeb
          ? 'web'
          : (Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'other'),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
