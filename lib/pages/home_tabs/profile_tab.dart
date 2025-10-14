import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chcg_iot_app/core/api_service.dart';
import 'package:chcg_iot_app/pages/login_page.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

String formatDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  final date = DateTime.tryParse(isoString);
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toLocal());
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
  String appVersion = ''; 
  bool _isDeactivating = false; // ← 新增：註銷中載入狀態

  @override
  void initState() {
    super.initState();
    fetchAccount();
    fetchAppVersion(); // ← 初始化時讀取版本
  }

  Future<void> _confirmDeactivateAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty || token == 'GUEST_MODE') {
      if (mounted) {
        await _showLoginRequiredDialog();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeactivating,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('註銷帳戶'),
              content: const Text(
                '註銷後將立即停用此帳號的登入與使用權限，'
                '並在 30 天後永久刪除所有與該帳戶相關的資料（依後端政策執行）。\n\n'
                '此操作無法復原，你確定要繼續嗎？',
              ),
              actions: [
                TextButton(
                  onPressed: _isDeactivating ? null : () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: _isDeactivating
                      ? null
                      : () async {
                          setStateDialog(() => _isDeactivating = true);
                          try {
                            final res = await apiService.deactivateAccount(token);
                            if (mounted) Navigator.pop(ctx, true);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['message'] ?? '已提交註銷申請')),
                              );
                            }
                            // 自動登出
                            await prefs.remove('token');
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                            }
                          } catch (e) {
                            setStateDialog(() => _isDeactivating = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst('Exception: ', ''),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: _isDeactivating
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('確認註銷'),
                ),
              ],
            );
          },
        );
      },
    );

    // 使用者取消或關閉視窗
    if (confirmed != true) return;
  }

  Future<void> showAppInfoDialog() async {
    final p = await PackageInfo.fromPlatform();
    final di = DeviceInfoPlugin();

    String os = '';
    String device = '';

    if (Platform.isAndroid) {
      final a = await di.androidInfo;
      os = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
      device = '${a.manufacturer} ${a.model}';
    } else if (Platform.isIOS) {
      final i = await di.iosInfo;
      os = 'iOS ${i.systemVersion}';
      device = '${i.name} ${i.model}';
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('App 資訊'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('App 名稱', p.appName),
                _kv('套件 ID', p.packageName),
                _kv('版本號', p.version),
                _kv('Build', p.buildNumber),
                const Divider(),
                _kv('作業系統', os),
                _kv('裝置', device),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('關閉'),
              ),
            ],
          ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '$k：',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Future<void> fetchAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version; // e.g. "1.0.0"
    });
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
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
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
        backgroundColor: const Color(0xFF7B4DBB),
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
                            const SizedBox(height: 8),
                            InfoRow(
                              title: '版本號',
                              value:
                                  appVersion.isNotEmpty ? appVersion : '讀取中...',
                              onTap:
                                  appVersion.isNotEmpty
                                      ? showAppInfoDialog
                                      : null,
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
                                backgroundColor: const Color(0xFF7B4DBB),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // ↓↓↓ 新增：註銷帳戶按鈕（紅色）
                            ElevatedButton.icon(
                              onPressed: _confirmDeactivateAccount,
                              icon: const Icon(Icons.delete_forever, color: Colors.white),
                              label: const Text('註銷帳戶（30天後永久刪除）', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
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
  final VoidCallback? onTap; // ← 新增

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$title：',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: onTap == null ? Colors.black87 : const Color(0xFF7B4DBB),
              decoration:
                  onTap == null
                      ? TextDecoration.none
                      : TextDecoration.underline,
            ),
          ),
        ),
        if (onTap != null)
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF7B4DBB)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}
