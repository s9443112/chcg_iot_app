import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart'; // <-- 要引入！
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
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
