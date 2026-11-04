import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> initialize() async {
    // طلب أذن الإشعارات من المستخدم
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

    // الاستماع للإشعارات الواردة أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        debugPrint('🔔 وصل إشعار جديد: ${notification.title} - ${notification.body}');
      }
    });

    // جلب التوكن الخاص بالجهاز لإرسال الإشعارات المستهدفة
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: $token');
  }
}
