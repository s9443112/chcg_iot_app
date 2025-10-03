import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart'; // <-- 要引入！
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print('🔴 背景收到通知: ${message.messageId}');
// }


Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  // await Firebase.initializeApp();

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // await FirebaseMessaging.instance.requestPermission();
  
  // String? token = await FirebaseMessaging.instance.getToken();
  // print('✅ FCM Token: $token');

  // await FirebaseMessaging.instance.subscribeToTopic("all_news");

  runApp(
    ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MyApp();
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriTalk IoT',
      theme: ThemeData(
        primaryColor: const Color(0xFF7B4DBB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B4DBB)),
        fontFamily: 'SourceHanSansTW',
        useMaterial3: true, // Material 3！
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => const HomePage(), // <-- 新增home
      },
    );
  }
}
