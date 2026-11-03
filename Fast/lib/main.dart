import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/auth/phone_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase بمفاتيح المشروع الخاصة بك
  try {
    await Supabase.initialize(
      url: 'https://pzokmpthkpuofrntufyp.supabase.co',
      anonKey: 'Sb_publishable_uI01Ippgs8yXi9k18JO8DQ_Zm74RqQf',
    );
  } catch (e) {
    debugPrint('⚠️ خطأ في اتصال Supabase: $e');
  }

  // التحقق من جلسة المستخدم لمنع تكرار شاشة تسجيل الدخول
  final prefs = await SharedPreferences.getInstance();
  final bool isUserLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: FastApp(isUserLoggedIn: isUserLoggedIn),
    ),
  );
}

class FastApp extends StatelessWidget {
  final bool isUserLoggedIn;
  const FastApp({Key? key, required this.isUserLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'FAST – تعز',
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
      home: isUserLoggedIn ? const HomeScreen() : const PhoneAuthScreen(),
    );
  }
}
