import 'package:flutter/material.dart';
import '../core/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final jobTitleController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final apiService = ApiService();

  bool _loading = false;
  bool _obscurePwd = true;
  bool _obscurePwd2 = true;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    jobTitleController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if ((v ?? '').isEmpty) return 'Email 為必填';
    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailReg.hasMatch(v!)) return 'Email 格式不正確';
    return null;
  }

  String? _validateRequired(String? v, {String label = '此欄位'}) {
    if ((v ?? '').trim().isEmpty) return '$label 為必填';
    return null;
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').isEmpty) return '密碼為必填';
    if (v!.length < 8) return '密碼至少 8 碼';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if ((v ?? '').isEmpty) return '請再次輸入密碼';
    if (v != passwordController.text) return '兩次密碼不一致';
    return null;
  }

  Future<void> _register() async {
    // 驗證
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await apiService.register(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      jobTitle: jobTitleController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    setState(() => _loading = false);

    if (result != null && result['error'] == null) {
      final msg = result['message'] ?? '註冊成功，請等待審核或返回登入';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context); // 返回登入頁
      }
    } else {
      // 後端可能回 {"errors": {...}} 或 {"error": "xxx"}
      String err = '註冊失敗，請檢查輸入';
      final e = result?['error'];
      if (e is String && e.isNotEmpty) {
        err = e;
      } else if (e is Map<String, dynamic>) {
        // 把欄位錯誤摺成一行
        final msgs = <String>[];
        e.forEach((k, v) {
          if (v is List && v.isNotEmpty) {
            msgs.add('$k: ${v.join(", ")}');
          } else {
            msgs.add('$k: $v');
          }
        });
        if (msgs.isNotEmpty) err = msgs.join(' / ');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  InputDecoration _decor(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('註冊新帳號')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 標題
                      Text('建立你的帳戶',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),

                      // 帳號 / Email
                      TextFormField(
                        controller: usernameController,
                        decoration: _decor('帳號', icon: Icons.person),
                        validator: (v) => _validateRequired(v, label: '帳號'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: _decor('Email', icon: Icons.email),
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // 名 / 姓氏
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              decoration: _decor('名', icon: Icons.badge),
                              validator: (v) => _validateRequired(v, label: '名'),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lastNameController,
                              decoration: _decor('姓氏', icon: Icons.badge_outlined),
                              validator: (v) => _validateRequired(v, label: '姓氏'),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 職稱 / 電話（電話可選）
                      TextFormField(
                        controller: jobTitleController,
                        decoration: _decor('職稱', icon: Icons.work_outline),
                        validator: (v) => _validateRequired(v, label: '職稱'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: _decor('電話（選填）', icon: Icons.phone),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // 密碼 / 確認密碼
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePwd,
                        decoration: _decor('密碼（至少 8 碼）', icon: Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePwd ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                          ),
                        ),
                        validator: _validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: _obscurePwd2,
                        decoration: _decor('再次輸入密碼', icon: Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePwd2 ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePwd2 = !_obscurePwd2),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                        onFieldSubmitted: (_) {
                          if (!_loading) _register();
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(
                                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                              : const Text('送出註冊'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('已有帳號？返回登入'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
