import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'teacher_tuition_screen.dart';
import 'teacher_student_screen.dart';
import 'teacher_staff_screen.dart';
import 'teacher_class_screen.dart';
import '../../theme/app_colors.dart';
import '../../features/parent/screens/parent_list_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.watch<AuthProvider>().currentUser?.role == 'ADMIN'
              ? 'Quản trị viên'
              : 'Giáo viên',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _TeacherCard(
              title: 'Danh sách lớp',
              icon: Icons.diversity_3_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherClassScreen(),
                  ),
                );
              },
            ),
            _TeacherCard(
              title: 'Điểm danh',
              icon: Icons.event_available_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherClassScreen(attendanceMode: true),
                  ),
                );
              },
            ),
            _TeacherCard(
              title: 'Học sinh',
              icon: Icons.diversity_3_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherStudentScreen(),
                  ),
                );
              },
            ),
            _TeacherCard(
              title: 'Học phí',
              icon: Icons.payments_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherTuitionScreen(),
                  ),
                );
              },
            ),
            if (context.watch<AuthProvider>().currentUser?.role == 'ADMIN')
              _TeacherCard(
                title: 'Phụ huynh',
                icon: Icons.family_restroom_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentListScreen(),
                    ),
                  );
                },
              ),
            if (context.watch<AuthProvider>().currentUser?.role == 'ADMIN')
              _TeacherCard(
                title: 'Nhân viên',
                icon: Icons.badge_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherStaffScreen(),
                    ),
                  );
                },
              ),
          ],
          
        ),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _TeacherCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: AppColors.cardDecoration(radius: 22),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.accent,
              size: 28,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
