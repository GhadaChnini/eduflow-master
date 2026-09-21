import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM: ${message.notification?.title}');
}

class FCMService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Show notifications when app is in foreground too
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save token
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    if (token != null) await _saveToken(token);
    messaging.onTokenRefresh.listen(_saveToken);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Log foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM: ${message.notification?.title}');
    });
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) { debugPrint('FCM token error: $e'); }
  }

  static Future<void> deleteToken() async {
    await FirebaseMessaging.instance.deleteToken();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': null})
        .eq('id', user.id);
  }
}