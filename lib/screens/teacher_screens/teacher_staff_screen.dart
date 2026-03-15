import 'package:flutter/material.dart';
import 'teacher_add_staff_screen.dart';
import 'teacher_staff_detail_screen.dart';
import '../../theme/app_colors.dart';

class TeacherStaffScreen extends StatelessWidget {
  const TeacherStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffs = const [
      {
        'name': 'Nguyễn Thị A',
        'role': 'Giáo viên',
        'salary': 8000000,
      },
      {
        'name': 'Trần Văn B',
        'role': 'Trợ giảng',
        'salary': 5000000,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Nhân viên'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherAddStaffScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: staffs.length,
        itemBuilder: (_, i) {
          final s = staffs[i];
          return _StaffItem(
            name: s['name'] as String,
            role: s['role'] as String,
            salary: s['salary'] as int,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherStaffDetailScreen(
                    name: s['name'] as String,
                    role: s['role'] as String,
                    baseSalary: s['salary'] as int,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StaffItem extends StatelessWidget {
  final String name;
  final String role;
  final int salary;
  final VoidCallback onTap;

  const _StaffItem({
    required this.name,
    required this.role,
    required this.salary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _format(salary),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(int v) =>
      v.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );
}
