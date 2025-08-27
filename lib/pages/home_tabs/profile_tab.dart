import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:agritalk_iot_app/pages/login_page.dart';
import 'package:intl/intl.dart';

String formatDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  final date = DateTime.tryParse(isoString);
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toLocal()); // 轉換為本地時間
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final apiService = ApiService();
  Map<String, dynamic>? account;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAccount();
  }

  Future<void> _showLoginRequiredDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('請先登入'),
            content: const Text('您需要登入才能查看個人基本資訊。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 關閉對話框
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 關閉對話框
                  Navigator.pushReplacementNamed(context, '/'); // 返回登入頁
                },
                child: const Text('前往登入'),
              ),
            ],
          ),
    );
  }

  Future<void> fetchAccount() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty || token == 'GUEST_MODE') {
        if (mounted) {
          await _showLoginRequiredDialog();
        }
        return;
      }

      final result = await apiService.account(token);

      print(result);
      setState(() {
        account = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = '載入失敗：$e';
        isLoading = false;
      });
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void changePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    bool oldObscure = true;
    bool newObscure = true;
    bool confirmObscure = true;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('變更密碼'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldController,
                      obscureText: oldObscure,
                      decoration: InputDecoration(
                        labelText: '舊密碼',
                        suffixIcon: IconButton(
                          icon: Icon(
                            oldObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => oldObscure = !oldObscure);
                          },
                        ),
                      ),
                    ),
                    TextField(
                      controller: newController,
                      obscureText: newObscure,
                      decoration: InputDecoration(
                        labelText: '新密碼',
                        suffixIcon: IconButton(
                          icon: Icon(
                            newObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => newObscure = !newObscure);
                          },
                        ),
                      ),
                    ),
                    TextField(
                      controller: confirmController,
                      obscureText: confirmObscure,
                      decoration: InputDecoration(
                        labelText: '確認新密碼',
                        suffixIcon: IconButton(
                          icon: Icon(
                            confirmObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => confirmObscure = !confirmObscure);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final oldPwd = oldController.text.trim();
                      final newPwd = newController.text.trim();
                      final confirmPwd = confirmController.text.trim();

                      if (oldPwd.isEmpty ||
                          newPwd.isEmpty ||
                          confirmPwd.isEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('請填寫完整')));
                        return;
                      }

                      if (newPwd != confirmPwd) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('新密碼與確認密碼不一致')),
                        );
                        return;
                      }

                      try {
                        final res = await apiService.changePassword(
                          oldPwd,
                          newPwd,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res["message"] ?? '密碼更新成功')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('送出'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '個人資訊',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF065B4C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '帳號資訊',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
                              title: '帳號',
                              value: account?['username'] ?? '',
                            ),
                            InfoRow(
                              title: '姓名',
                              value:
                                  '${account?['first_name'] ?? ''} ${account?['last_name'] ?? ''}',
                            ),
                            InfoRow(
                              title: '信箱',
                              value: account?['email'] ?? '',
                            ),
                            InfoRow(
                              title: '加入時間',
                              value:
                                  formatDateTime(account?['date_joined']) ?? '',
                            ),
                            InfoRow(
                              title: '最近登入',
                              value:
                                  formatDateTime(account?['last_login']) ?? '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '帳戶操作',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: changePasswordDialog,
                              icon: const Icon(
                                Icons.lock_reset,
                                color: Colors.white,
                              ),
                              label: const Text(
                                '變更密碼',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF065B4C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('登出'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const InfoRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title：',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
