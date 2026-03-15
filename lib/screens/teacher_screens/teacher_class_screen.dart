import 'package:flutter/material.dart';
import 'teacher_class_detail_screen.dart';
import '../../theme/app_colors.dart';

class TeacherClassScreen extends StatelessWidget {
  const TeacherClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = const [
      {
        'name': 'Lớp Mầm 1',
        'count': 18,
        'schedule': '08:00 - 10:30',
      },
      {
        'name': 'Lớp Chồi 2',
        'count': 20,
        'schedule': '13:30 - 16:00',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Lớp học'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final c = classes[index];
          return _ClassItem(
            name: c['name'] as String,
            count: c['count'] as int,
            schedule: c['schedule'] as String,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherClassDetailScreen(
                    className: c['name'] as String,
                    schedule: c['schedule'] as String,
                    count: c['count'] as int,
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

class _ClassItem extends StatelessWidget {
  final String name;
  final int count;
  final String schedule;
  final VoidCallback onTap;

  const _ClassItem({
    required this.name,
    required this.count,
    required this.schedule,
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
              child: Icon(Icons.class_, color: Colors.white),
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
                  const SizedBox(height: 4),
                  Text(
                    'Giờ dạy: $schedule',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count HS',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
