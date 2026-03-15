import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TeacherStaffDetailScreen extends StatelessWidget {
  final String name;
  final String role;
  final int baseSalary;

  const TeacherStaffDetailScreen({
    super.key,
    required this.name,
    required this.role,
    required this.baseSalary,
  });

  @override
  Widget build(BuildContext context) {
    const workDays = 22;
    const attended = 20;
    final salary = (baseSalary / workDays * attended).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(label: 'Chức vụ', value: role),
            _InfoRow(label: 'Lương cơ bản', value: _format(baseSalary)),
            _InfoRow(label: 'Số buổi làm', value: '$attended / $workDays'),

            const SizedBox(height: 24),

            _SalarySummary(amount: salary),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalarySummary extends StatelessWidget {
  final int amount;

  const _SalarySummary({
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Lương thực nhận',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TeacherStaffDetailScreen._format(amount),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'VNĐ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
