import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _vapidKey =
    'BN_xnUXoyOUWPsZ1kd0tt1aEm82qat8m5dhrMTty19hDUVX-tYphND94WaDOw2VFp8YUySnl2WsTwG0w4zC66SM';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Push recebido em background: ${message.notification?.title}');
}

class PushService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('Push notifications: permissão negada');
        return;
      }

      if (!kIsWeb) {
        await _initLocalNotifications();
      }

      final token = kIsWeb
          ? await messaging.getToken(vapidKey: _vapidKey)
          : await messaging.getToken();

      if (token != null) {
        await _saveToken(token);
      }

      messaging.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen(_handleForeground);
    } catch (e) {
      debugPrint('Push notifications not available: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'eleva_notifications',
      'Notificações Eleva',
      description: 'Notificações do app Eleva',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    String platform;
    if (kIsWeb) {
      platform = 'web';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = 'ios';
    } else {
      platform = 'android';
    }

    try {
      await Supabase.instance.client.from('push_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
        },
        onConflict: 'user_id,token',
      );
    } catch (e) {
      debugPrint('Erro ao salvar push token: $e');
    }
  }

  static void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    if (kIsWeb) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'eleva_notifications',
          'Notificações Eleva',
          channelDescription: 'Notificações do app Eleva',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> removeToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: _vapidKey)
          : await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('push_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      }
    } catch (_) {}
  }
}
