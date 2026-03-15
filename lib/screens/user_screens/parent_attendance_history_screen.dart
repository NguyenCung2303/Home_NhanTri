import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ParentAttendanceHistoryScreen extends StatelessWidget {
  const ParentAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = const [
      {'date': '01/03', 'present': true},
      {'date': '02/03', 'present': true},
      {'date': '03/03', 'present': false},
      {'date': '04/03', 'present': true},
      {'date': '05/03', 'present': true},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Chi tiết buổi học'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (_, i) {
          final h = history[i];
          return _DayItem(
            date: h['date'] as String,
            present: h['present'] as bool,
          );
        },
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final String date;
  final bool present;

  const _DayItem({
    required this.date,
    required this.present,
  });

  @override
  Widget build(BuildContext context) {
    final color = present ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              present ? Icons.check : Icons.close,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ngày $date',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              present ? 'Có mặt' : 'Vắng',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
