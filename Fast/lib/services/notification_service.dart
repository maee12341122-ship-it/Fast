import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 👈 تهيئة نظام الإشعارات المحلية وإعداد قناة أندرويد
  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotificationsPlugin.initialize(initializationSettings);
      debugPrint('🟢 تم تهيئة نظام الإشعارات المحلي بنجاح');
    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة الإشعارات: $e');
    }
  }

  /// 👈 دالة طلب إذن الإشعارات رسمياً من النظام
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

  /// 👈 دالة عرض إشعار حقيقي وفوري يظهر على شاشة الهاتف للمستخدم
  static Future<void> showLocalNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fast_delivery_channel_id',
        'تنبيهات تطبيق FAST',
        channelDescription: 'قناة إشعارات طلبات وحالة توصيل FAST في تعز',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.show(
        DateTime.now().millisecond, // معرف فريد للإشعار
        title,
        body,
        notificationDetails,
      );
      
      debugPrint('🔔 [تم إرسال إشعار حقيقي بنجاح]: $title - $body');
    } catch (e) {
      debugPrint('❌ خطأ في عرض الإشعار المحلي: $e');
    }
  }
}
