
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../login_screen.dart';
import '../../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    final fullName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : 'Người dùng';

    final role = _roleLabel(user?.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Cá nhân'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            fullName: fullName,
            role: role,
          ),

          const SizedBox(height: 24),

          _SettingTile(
            icon: Icons.notifications_active_rounded,
            title: 'Thông báo',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.primary,
            ),
          ),

          _SettingTile(
            icon: Icons.lock_rounded,
            title: 'Đổi mật khẩu',
            onTap: () {
              // TODO
            },
          ),

          const SizedBox(height: 12),

          _SettingTile(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            titleColor: Colors.orangeAccent,
            onTap: () => _logout(context),
          ),

          const SizedBox(height: 24),

          _DangerTile(
            title: 'Xoá tài khoản',
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  static String _roleLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'PARENT':
        return 'Phụ huynh';
      case 'TEACHER':
        return 'Giáo viên';
      case 'ADMIN':
        return 'Quản trị viên';
      case 'ASSISTANT':
        return 'Trợ giảng';
      default:
        return 'Người dùng';
    }
  }

  static Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá tài khoản'),
        content: const Text(
          'Bạn có chắc chắn muốn xoá tài khoản?\n'
          'Dữ liệu sẽ bị xoá vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Xoá',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String role;

  const _ProfileHeader({
    required this.fullName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accent,
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: titleColor),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _DangerTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

