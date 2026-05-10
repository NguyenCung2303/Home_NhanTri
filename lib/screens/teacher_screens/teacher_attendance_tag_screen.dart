import 'package:flutter/material.dart';

import '../../data/models/student_tag_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../theme/app_colors.dart';
import 'teacher_attendance_screen.dart';

class TeacherAttendanceTagScreen extends StatefulWidget {
  const TeacherAttendanceTagScreen({super.key});

  @override
  State<TeacherAttendanceTagScreen> createState() => _TeacherAttendanceTagScreenState();
}

class _TeacherAttendanceTagScreenState extends State<TeacherAttendanceTagScreen> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  List<StudentTagModel> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await _attendanceRepository.getActiveStudentTags();
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _isLoading = false;
    });
  }

  void _openAttendance(StudentTagModel tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherAttendanceScreen(
          classId: tag.id,
          className: tag.tagName,
          attendanceMode: AttendanceMode.tag,
        ),
      ),
    ).then((_) => _loadTags());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Chọn nhóm để điểm danh'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTags,
              child: _tags.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.sell_outlined, size: 56, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có nhóm trình độ nào để điểm danh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withOpacity(0.18)),
                          ),
                          child: const Text(
                            'Điểm danh theo nhóm trình độ giúp giáo viên thấy đúng học sinh cần học buổi đó, ví dụ Nhập môn, Cơ bản, Tuyển trường.',
                            style: TextStyle(color: AppColors.textPrimary, height: 1.35, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._tags.map(
                          (tag) => _TagCard(
                            tag: tag,
                            onTap: () => _openAttendance(tag),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _TagCard extends StatelessWidget {
  final StudentTagModel tag;
  final VoidCallback onTap;

  const _TagCard({required this.tag, required this.onTap});

  IconData get _icon {
    switch (tag.tagCode) {
      case 'NHAP_MON':
        return Icons.flag_outlined;
      case 'CO_BAN':
        return Icons.extension_outlined;
      case 'TUYEN_TRUONG':
        return Icons.emoji_events_outlined;
      case 'NANG_CAO':
        return Icons.psychology_outlined;
      default:
        return Icons.sell_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentSoft,
                child: Icon(_icon, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.tagName,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tag.description ?? 'Nhóm học sinh theo trình độ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tag.studentCount} học sinh',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
