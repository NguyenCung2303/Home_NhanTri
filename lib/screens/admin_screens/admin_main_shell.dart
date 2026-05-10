import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../teacher_screens/teacher_home_screen.dart';
import '../teacher_screens/teacher_class_screen.dart';
import '../teacher_screens/teacher_schedule_screen.dart';
import '../teacher_screens/teacher_message_screen.dart';
import '../teacher_screens/teacher_profile_screen.dart';
import '../todo/todo_home_screen.dart';
import '../../features/enrollment/screens/admin_enrollment_requests_screen.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeacherHomeScreen(),
    TeacherClassScreen(),
    TeacherScheduleScreen(),
    TeacherMessageScreen(),
    AdminEnrollmentRequestsScreen(),
    TodoHomeScreen(),
    TeacherProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AdminBottomBar(
        currentIndex: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _AdminBottomBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.dashboard, label: 'Tổng quan', active: currentIndex == 0, onTap: () => onChanged(0)),
          _NavItem(icon: Icons.class_, label: 'Lớp học', active: currentIndex == 1, onTap: () => onChanged(1)),
          _NavItem(icon: Icons.schedule, label: 'Lịch học', active: currentIndex == 2, onTap: () => onChanged(2)),
          _NavItem(icon: Icons.chat, label: 'Tin nhắn', active: currentIndex == 3, onTap: () => onChanged(3)),
          _NavItem(icon: Icons.assignment_ind, label: 'Đăng ký', active: currentIndex == 4, onTap: () => onChanged(4)),
          _NavItem(icon: Icons.checklist, label: 'To-Do', active: currentIndex == 5, onTap: () => onChanged(5)),
          _NavItem(icon: Icons.person, label: 'Cá nhân', active: currentIndex == 6, onTap: () => onChanged(6)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
