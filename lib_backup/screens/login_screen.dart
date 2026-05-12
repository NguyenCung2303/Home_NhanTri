import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/enrollment/screens/enrollment_request_screen.dart';
import 'admin_screens/admin_main_shell.dart';
import 'teacher_screens/teacher_main_shell.dart';
import 'user_screens/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ số điện thoại/email và mật khẩu')),
      );
      return;
    }

    final success = await authProvider.login(username, password);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại')),
      );
      return;
    }

    final role = authProvider.currentUser?.role.trim().toUpperCase();
    Widget? nextScreen;

    switch (role) {
      case 'ADMIN':
        nextScreen = const AdminMainShell();
        break;
      case 'TEACHER':
      case 'ASSISTANT':
        nextScreen = const TeacherMainShell();
        break;
      case 'PARENT':
      case 'USER':
        nextScreen = const MainShell();
        break;
      default:
        nextScreen = null;
    }

    if (nextScreen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tài khoản chưa có quyền truy cập: ${role ?? 'UNKNOWN'}')),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen!),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.softShadow,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Home Nhân Trí',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quản lý trung tâm đào tạo cờ vua',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppColors.cardDecoration(radius: 26),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          hint: 'Số điện thoại hoặc email',
                          icon: Icons.person_search_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!authProvider.isLoading) _handleLogin();
                        },
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          hint: 'Mật khẩu',
                          icon: Icons.lock_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: authProvider.isLoading ? null : _handleLogin,
                          icon: authProvider.isLoading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.login_rounded),
                          label: authProvider.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Đăng nhập'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EnrollmentRequestScreen()),
                            );
                          },
                    icon: const Icon(Icons.app_registration_rounded),
                    label: const Text('Phụ huynh mới? Đăng ký học'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tài khoản do trung tâm cấp sẽ đăng nhập bằng SĐT/email và mật khẩu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
