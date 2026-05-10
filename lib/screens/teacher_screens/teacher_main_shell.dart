import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'teacher_class_screen.dart';
import 'teacher_attendance_tag_screen.dart';
import 'teacher_learning_guidance_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherMainShell extends StatefulWidget {
  const TeacherMainShell({super.key});

  @override
  State<TeacherMainShell> createState() => _TeacherMainShellState();
}

class _TeacherMainShellState extends State<TeacherMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeacherClassScreen(),
    TeacherAttendanceTagScreen(),
    TeacherLearningGuidanceScreen(),
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
        onChanged: (i) => setState(() => _currentIndex = i),
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
          _NavItem(icon: Icons.class_, label: 'Lớp phụ trách', active: currentIndex == 0, onTap: () => onChanged(0)),
          _NavItem(icon: Icons.fact_check, label: 'Điểm danh', active: currentIndex == 1, onTap: () => onChanged(1)),
          _NavItem(icon: Icons.school, label: 'Định hướng', active: currentIndex == 2, onTap: () => onChanged(2)),
          _NavItem(icon: Icons.person, label: 'Cá nhân', active: currentIndex == 3, onTap: () => onChanged(3)),
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
        width: 72,
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
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
