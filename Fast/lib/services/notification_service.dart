import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // طلب أذن الإشعارات من المستخدم (مهم جداً لأندرويد 13+ و iOS)
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🟢 تم منح إذن الإشعارات بنجاح');
    } else {
      debugPrint('⚠️ تم رفض إذن الإشعارات من قبل المستخدم');
    }

    // إعداد الإشعارات المحلية لتظهر في شريط الإشعارات
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(initializationSettings);

    // الاستماع للإشعارات الواردة أثناء فتح التطبيق
    FirebaseMessaging.onMessage.ogat((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fast_delivery_channel',
              'تنبيهات تطبيق Fast',
              channelDescription: 'قناة إشعارات طلبات توصيل Fast',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(0xFFFFC107), // لون ذهبي متناسق مع هويتنا
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // جلب التوكن الخاص بالجهاز (لإرسال إشعارات موجهة لهذا المستخدم عبر Supabase أو Firebase)
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: $token');
  }
}
