import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // Firebase deve ser configurado no projeto antes de usar push
      // 1. Criar projeto no Firebase Console
      // 2. Adicionar google-services.json (Android) em android/app/
      // 3. Adicionar GoogleService-Info.plist (iOS) em ios/Runner/
      // 4. Descomentar o código abaixo:

      // await Firebase.initializeApp();
      // final messaging = FirebaseMessaging.instance;
      //
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      //
      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   final token = await messaging.getToken();
      //   if (token != null) {
      //     await _saveToken(token);
      //   }
      //
      //   messaging.onTokenRefresh.listen(_saveToken);
      //
      //   FirebaseMessaging.onMessage.listen(_handleForeground);
      //   FirebaseMessaging.onMessageOpenedApp.listen(_handleBackground);
      // }
    } catch (e) {
      debugPrint('Push notifications not available: $e');
    }
  }

  // ignore: unused_element
  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    await Supabase.instance.client.from('push_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': platform,
    }, onConflict: 'user_id,token');
  }

  // static void _handleForeground(RemoteMessage message) {
  //   // Mostrar local notification quando app está em foreground
  //   // Usar flutter_local_notifications aqui
  // }

  // static void _handleBackground(RemoteMessage message) {
  //   // Navegar para tela de notificações quando usuário toca na push
  // }
}
