import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationSender {
  // Send push notification to a single user
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .single();

      final token = profile['fcm_token'] as String?;
      debugPrint('📱 FCM sending to $userId, token: ${token?.substring(0, 20)}...');
      if (token == null || token.isEmpty) {
        debugPrint('❌ No FCM token for $userId');
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      debugPrint('✅ FCM response: ${response.data}');
    } catch (e) {
      debugPrint('❌ Push notification error: $e');
    }
  }

  // Send to multiple users
  static Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    for (final userId in userIds) {
      await sendToUser(userId: userId, title: title, body: body, data: data);
    }
  }
}