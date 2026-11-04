import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> initialize() async {
    try {
      debugPrint('🟢 تم تهيئة نظام الإشعارات الداخلي بنجاح');
    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة الإشعارات: $e');
    }
  }

  static void showLocalNotification(String title, String body) {
    debugPrint('🔔 [إشعار فوري جديد]: $title -$body');
  }
}
