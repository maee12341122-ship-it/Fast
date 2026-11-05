import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';

// دالة معالجة الإشعارات في الخلفية (تعمل حتى لو التطبيق مغلق كلياً)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("📥 تم استلام إشعار في الخلفية: ${message.messageId}");
  } catch (e) {
    debugPrint("⚠️ خطأ في معالجة إشعار الخلفية: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase الأساسية لضمان عمل الإشعارات
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ خطأ في تهيئة Firebase: $e');
  }

  try {
    await Supabase.initialize(
      url: 'https://pzokmpthkpuofrntufyp.supabase.co',
      anonKey: 'sb_publishable_uI01Ippgs8yXi9k18JO8DQ_Zm74RqQf',
    );
  } catch (e) {
    debugPrint('⚠️ خطأ في اتصال Supabase: $e');
  }

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ خطأ في تهيئة الإشعارات: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const FastApp(),
    ),
  );
}

class FastApp extends StatelessWidget {
  const FastApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'Fast',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.light(
          primary: Colors.amber,
          secondary: Colors.amber,
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amber,
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.amber,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
