import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  /// 👈 تهيئة الإشعارات عبر Firebase وطلب الأذونات بدون أي ملفات أندرويد
  static Future<void> initialize() async {
    try {
      await requestNotificationPermission();

      // الاستماع للإشعارات في الواجهة الأمامية
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [إشعار مباشر]: ${message.notification?.title} - ${message.notification?.body}');
      });

      // التعامل مع النقر على الإشعار
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [النقر على الإشعار]: ${message.data}');
      });

      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint('📱 [FCM Token]: $token');

      debugPrint('🟢 تم تهيئة نظام الإشعارات بنجاح');
    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة الإشعارات: $e');
    }
  }

  /// 👈 طلب إذن الإشعارات من النظام
  static Future<bool> requestNotificationPermission() async {
    try {
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ خطأ في طلب إذن الإشعارات: $e');
      return false;
    }
  }

  /// 👈 دالة فارغة توافقية (Firebase سيقوم بعرض الإشعار في الشريط تلقائياً)
  static Future<void> showLocalNotification(String title, String body) async {
    debugPrint('📢 [FAST Notification]: $title - $body');
  }
}
