import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static Future<void> initialize() async {
    try {
      debugPrint('🟢 تم تهيئة نظام الإشعارات الداخلي بنجاح');
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

  static void showLocalNotification(String title, String body) {
    debugPrint('🔔 [إشعار فوري جديد]: $title -$body');
  }
}