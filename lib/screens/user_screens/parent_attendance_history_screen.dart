import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/attendance_record_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/student/providers/student_provider.dart';
import '../../theme/app_colors.dart';

class ParentAttendanceHistoryScreen extends StatefulWidget {
  const ParentAttendanceHistoryScreen({super.key});

  @override
  State<ParentAttendanceHistoryScreen> createState() => _ParentAttendanceHistoryScreenState();
}

class _ParentAttendanceHistoryScreenState extends State<ParentAttendanceHistoryScreen> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  List<AttendanceRecordModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    await context.read<StudentProvider>().loadStudentsByParentUserId(userId);
    final history = await _attendanceRepository.getAttendanceByParentUserId(userId);

    if (!mounted) return;
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  String _studentName(String studentId, List<StudentModel> students) {
    try {
      return students.firstWhere((e) => e.id == studentId).fullName;
    } catch (_) {
      return 'Không rõ học sinh';
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Chi tiết buổi học'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có lịch sử điểm danh',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final h = _history[i];
                    return _DayItem(
                      date: h.attendanceDate,
                      studentName: _studentName(h.studentId, students),
                      present: h.isPresent,
                    );
                  },
                ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final String date;
  final String studentName;
  final bool present;

  const _DayItem({
    required this.date,
    required this.studentName,
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
            child: Icon(present ? Icons.check : Icons.close, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày $date',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
