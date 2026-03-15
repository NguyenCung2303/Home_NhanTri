import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TeacherAttendanceDayDetailScreen extends StatelessWidget {
  final String className;
  final String date;

  const TeacherAttendanceDayDetailScreen({
    super.key,
    required this.className,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final students = const [
      {'name': 'Nguyễn Văn Minh', 'present': true},
      {'name': 'Trần Thị An', 'present': true},
      {'name': 'Lê Hoàng Long', 'present': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('$date · $className'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: students.length,
        itemBuilder: (_, i) {
          final s = students[i];
          return _DayAttendanceItem(
            name: s['name'] as String,
            present: s['present'] as bool,
          );
        },
      ),
    );
  }
}

class _DayAttendanceItem extends StatelessWidget {
  final String name;
  final bool present;

  const _DayAttendanceItem({
    required this.name,
    required this.present,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        present ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(
              present ? Icons.check : Icons.close,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            present ? 'Có mặt' : 'Vắng',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
