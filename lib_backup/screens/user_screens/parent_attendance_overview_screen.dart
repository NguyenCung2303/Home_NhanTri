import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/attendance_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'parent_attendance_history_screen.dart';

class ParentAttendanceOverviewScreen extends StatefulWidget {
  const ParentAttendanceOverviewScreen({super.key});

  @override
  State<ParentAttendanceOverviewScreen> createState() => _ParentAttendanceOverviewScreenState();
}

class _ParentAttendanceOverviewScreenState extends State<ParentAttendanceOverviewScreen> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  AttendanceSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final summary = await _attendanceRepository.getAttendanceSummaryByParentUserId(userId);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const feePerSession = 150000;
    final attended = _summary?.presentCount ?? 0;
    final absent = _summary?.absentCount ?? 0;
    final totalFee = attended * feePerSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Buổi học của con'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryCard(
                    attended: attended,
                    absent: absent,
                    totalFee: totalFee,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      label: const Text(
                        'Xem chi tiết từng buổi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ParentAttendanceHistoryScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int attended;
  final int absent;
  final int totalFee;

  const _SummaryCard({
    required this.attended,
    required this.absent,
    required this.totalFee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan tháng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(label: 'Có mặt', value: attended.toString(), color: AppColors.success),
              const SizedBox(width: 12),
              _StatBox(label: 'Vắng', value: absent.toString(), color: AppColors.warning),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Học phí tạm tính', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                '${_format(totalFee)} ₫',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _format(int v) => v.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
