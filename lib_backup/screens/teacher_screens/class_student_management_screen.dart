import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/student_model.dart';
import '../../features/student/providers/student_provider.dart';
import '../../theme/app_colors.dart';

class ClassStudentManagementScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool canManage;

  const ClassStudentManagementScreen({
    super.key,
    required this.classId,
    required this.className,
    this.canManage = false,
  });

  @override
  State<ClassStudentManagementScreen> createState() => _ClassStudentManagementScreenState();
}

class _ClassStudentManagementScreenState extends State<ClassStudentManagementScreen> {
  final Set<String> _selectedStudentIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final provider = context.read<StudentProvider>();
    await provider.loadStudentsByClass(widget.classId);
    if (widget.canManage) {
      await provider.loadAvailableStudentsForClass(widget.classId);
    }
  }

  Future<void> _assignSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) {
      _showSnack('Chọn ít nhất 1 học sinh để thêm vào lớp');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<StudentProvider>().assignStudentsToClass(
            widget.classId,
            _selectedStudentIds.toList(),
          );
      _selectedStudentIds.clear();
      if (!mounted) return;
      _showSnack('Đã gán học sinh vào lớp');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không thể gán học sinh: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _removeStudent(StudentModel student) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xóa khỏi lớp', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Bạn có chắc muốn xóa ${student.fullName} khỏi lớp ${widget.className} không?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<StudentProvider>().removeStudentFromClass(widget.classId, student.id);
      if (!mounted) return;
      _showSnack('Đã xóa học sinh khỏi lớp');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không thể xóa học sinh: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final classStudents = provider.students;
    final availableStudents = provider.availableStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Học sinh · ${widget.className}'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionTitle(
                    title: 'Danh sách học sinh trong lớp',
                    subtitle: '${classStudents.length} học sinh',
                  ),
                  const SizedBox(height: 12),
                  if (classStudents.isEmpty)
                    const _EmptyCard(message: 'Lớp này chưa có học sinh nào')
                  else
                    ...classStudents.map(
                      (student) => _StudentCard(
                        student: student,
                        trailing: widget.canManage
                            ? IconButton(
                                onPressed: _isSubmitting ? null : () => _removeStudent(student),
                                icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                                tooltip: 'Xóa khỏi lớp',
                              )
                            : null,
                      ),
                    ),
                  if (widget.canManage) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'Gán thêm học sinh vào lớp',
                      subtitle: availableStudents.isEmpty
                          ? 'Không còn học sinh khả dụng'
                          : 'Chọn một hoặc nhiều học sinh',
                    ),
                    const SizedBox(height: 12),
                    if (availableStudents.isEmpty)
                      const _EmptyCard(message: 'Tất cả học sinh hiện có đã nằm trong lớp này')
                    else ...[
                      ...availableStudents.map(
                        (student) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CheckboxListTile(
                            value: _selectedStudentIds.contains(student.id),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedStudentIds.add(student.id);
                                      } else {
                                        _selectedStudentIds.remove(student.id);
                                      }
                                    });
                                  },
                            title: Text(
                              student.fullName,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              _studentDetailText(student),
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            activeColor: AppColors.accent,
                            checkColor: Colors.white,
                            tileColor: AppColors.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _assignSelectedStudents,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.person_add_alt_1, color: Colors.white),
                          label: Text(
                            _isSubmitting ? 'Đang xử lý...' : 'Gán học sinh đã chọn',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  String _studentDetailText(StudentModel student) {
    final values = [student.school, student.grade]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .cast<String>()
        .toList();
    return values.isEmpty ? 'Chưa có thông tin trường/lớp' : values.join(' • ');
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final Widget? trailing;

  const _StudentCard({required this.student, this.trailing});

  @override
  Widget build(BuildContext context) {
    final details = [student.school, student.grade]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .cast<String>()
        .join(' • ');

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
            backgroundColor: AppColors.accent.withOpacity(0.18),
            child: const Icon(Icons.person_outline, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.isEmpty ? 'Chưa có thông tin trường/lớp' : details,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
