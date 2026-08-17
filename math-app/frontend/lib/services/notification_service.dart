import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Ensure Firebase is initialized before accessing messaging
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized — skipping FCM registration');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      if (!kIsWeb) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          await _registerToken(messaging);
        }
      } else {
        await _registerToken(messaging);
      }

      messaging.onTokenRefresh.listen((token) {
        _subscribeBackend(token);
      });
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  Future<void> _registerToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _subscribeBackend(token);
      }
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  Future<void> _subscribeBackend(String token) async {
    try {
      await ApiService().post('/notifications/subscribe', data: {
        'fcm_token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
      });
    } catch (e) {
      debugPrint('Backend subscription failed: $e');
    }
  }

  Future<void> unsubscribe() async {
    try {
      await ApiService().post('/notifications/unsubscribe', data: {});
      if (!kIsWeb) {
        final messaging = FirebaseMessaging.instance;
        await messaging.deleteToken();
      }
    } catch (e) {
      debugPrint('Unsubscribe failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final resp = await ApiService().get('/notifications/preferences');
      return resp['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Get preferences failed: $e');
      return null;
    }
  }

  Future<bool> updatePreferences({bool? dailyReminderEnabled, int? reminderHour}) async {
    try {
      final data = <String, dynamic>{};
      if (dailyReminderEnabled != null) data['daily_reminder_enabled'] = dailyReminderEnabled;
      if (reminderHour != null) data['reminder_hour'] = reminderHour;
      await ApiService().put('/notifications/preferences', data: data);
      return true;
    } catch (e) {
      debugPrint('Update preferences failed: $e');
      return false;
    }
  }
}
