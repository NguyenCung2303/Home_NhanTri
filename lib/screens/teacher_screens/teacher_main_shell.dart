import 'package:flutter/material.dart';
import 'teacher_home_screen.dart';
import 'teacher_class_screen.dart';
import 'teacher_message_screen.dart';
import 'teacher_profile_screen.dart';
import '../todo/todo_home_screen.dart';
import '../../theme/app_colors.dart';

class TeacherMainShell extends StatefulWidget {
  const TeacherMainShell({super.key});

  @override
  State<TeacherMainShell> createState() => _TeacherMainShellState();
}

class _TeacherMainShellState extends State<TeacherMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeacherHomeScreen(),
    TeacherClassScreen(),
    TeacherMessageScreen(),
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
      bottomNavigationBar: _TeacherBottomBar(
        currentIndex: _currentIndex,
        onChanged: (i) {
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _TeacherBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _TeacherBottomBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A31),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard,
            label: 'Tổng quan',
            active: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            icon: Icons.class_,
            label: 'Lớp học',
            active: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            icon: Icons.chat,
            label: 'Tin nhắn',
            active: currentIndex == 2,
            onTap: () => onChanged(2),
          ),
          _NavItem(
            icon: Icons.checklist,
            label: 'To-Do',
            active: currentIndex == 3,
            onTap: () => onChanged(3),
          ),
          _NavItem(
            icon: Icons.person,
            label: 'Cá nhân',
            active: currentIndex == 4,
            onTap: () => onChanged(4),
          ),
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
    final color = active ? const Color(0xFFE85B7A) : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
