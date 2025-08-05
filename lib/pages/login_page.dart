import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  bool _rememberMe = false; // <-- 多一個記憶密碼選項

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';

    if (savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      setState(() {
        usernameController.text = savedUsername;
        passwordController.text = savedPassword;
        _rememberMe = true; // 有存過的話自動打勾
      });
    }
  }

  Future<void> _login(BuildContext context, {bool isGuest = false}) async {
    final username = isGuest ? 'guest' : usernameController.text;
    final password = isGuest ? 'guest' : passwordController.text;
    String? fcm_token = await FirebaseMessaging.instance.getToken();

    final result = await apiService.login(username, password, fcm_token);
    if (result != null && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);

      if (!isGuest) {
        if (_rememberMe) {
          await prefs.setString('saved_username', username);
          await prefs.setString('saved_password', password);
        } else {
          await prefs.remove('saved_username');
          await prefs.remove('saved_password');
        }
      }

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isGuest ? '訪客登入失敗' : '登入失敗，請檢查帳號密碼')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            // ← 防止鍵盤彈出時overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo-01.png', width: 180),
                const SizedBox(height: 24),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: '帳號'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密碼'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('記住帳號密碼'),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _login(context),
                  child: const Text('登入'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('token', 'GUEST_MODE');
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text('訪客瀏覽'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
