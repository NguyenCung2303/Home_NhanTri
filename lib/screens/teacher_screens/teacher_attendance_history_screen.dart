import 'package:flutter/material.dart';
import 'teacher_attendance_day_detail_screen.dart';
import '../../theme/app_colors.dart';

class TeacherAttendanceHistoryScreen extends StatelessWidget {
  final String className;

  const TeacherAttendanceHistoryScreen({
    super.key,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final history = const [
      {
        'date': '20/03/2024',
        'present': 16,
        'absent': 2,
      },
      {
        'date': '19/03/2024',
        'present': 17,
        'absent': 1,
      },
      {
        'date': '18/03/2024',
        'present': 15,
        'absent': 3,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Lịch sử điểm danh · $className'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (_, i) {
          final h = history[i];
          return _HistoryItem(
            date: h['date'] as String,
            present: h['present'] as int,
            absent: h['absent'] as int,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherAttendanceDayDetailScreen(
                    className: className,
                    date: h['date'] as String,
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

class _HistoryItem extends StatelessWidget {
  final String date;
  final int present;
  final int absent;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.date,
    required this.present,
    required this.absent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Có mặt: $present',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Vắng: $absent',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
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
