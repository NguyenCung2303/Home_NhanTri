import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/parent_model.dart';
import '../../../data/models/student_model.dart';
import '../../../theme/app_colors.dart';
import '../providers/parent_provider.dart';

class ParentStudentManagementScreen extends StatefulWidget {
  final ParentModel parent;

  const ParentStudentManagementScreen({
    super.key,
    required this.parent,
  });

  @override
  State<ParentStudentManagementScreen> createState() => _ParentStudentManagementScreenState();
}

class _ParentStudentManagementScreenState extends State<ParentStudentManagementScreen> {
  final Set<String> _selectedStudentIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final provider = context.read<ParentProvider>();
    await provider.loadParentStudents(widget.parent.id);
    await provider.loadAvailableStudentsForParent(widget.parent.id);
  }

  Future<void> _assignSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) {
      _showSnack('Chọn ít nhất 1 học sinh để gán cho phụ huynh');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<ParentProvider>().assignStudentsToParent(
            widget.parent.id,
            _selectedStudentIds.toList(),
          );
      _selectedStudentIds.clear();
      if (!mounted) return;
      _showSnack('Đã gán học sinh cho phụ huynh');
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
        title: const Text(
          'Bỏ liên kết học sinh',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Bạn có chắc muốn bỏ ${student.fullName} khỏi phụ huynh ${widget.parent.fullName} không?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ liên kết', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<ParentProvider>().removeStudentFromParent(widget.parent.id, student.id);
      if (!mounted) return;
      _showSnack('Đã bỏ liên kết học sinh');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không thể bỏ liên kết: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentProvider>();
    final linkedStudents = provider.parentStudents;
    final availableStudents = provider.availableStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.parent.fullName),
        centerTitle: true,
      ),
      body: provider.isLoading && !_isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ParentInfoCard(parent: widget.parent),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Học sinh đang liên kết',
                    subtitle: linkedStudents.isEmpty
                        ? 'Phụ huynh này chưa được gán học sinh nào'
                        : '${linkedStudents.length} học sinh',
                  ),
                  const SizedBox(height: 12),
                  if (linkedStudents.isEmpty)
                    const _EmptyCard(message: 'Chưa có học sinh. Gán ngay bên dưới để phụ huynh xem đúng dữ liệu con.')
                  else
                    ...linkedStudents.map(
                      (student) => _StudentCard(
                        student: student,
                        trailing: IconButton(
                          onPressed: _isSubmitting ? null : () => _removeStudent(student),
                          icon: const Icon(Icons.link_off, color: Colors.redAccent),
                          tooltip: 'Bỏ liên kết',
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Gán thêm học sinh',
                    subtitle: availableStudents.isEmpty
                        ? 'Không còn học sinh khả dụng'
                        : 'Chọn một hoặc nhiều học sinh',
                  ),
                  const SizedBox(height: 12),
                  if (availableStudents.isEmpty)
                    const _EmptyCard(message: 'Tất cả học sinh hiện có đã được liên kết với phụ huynh này')
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
                            : const Icon(Icons.family_restroom, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Đang xử lý...' : 'Gán học sinh đã chọn',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
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

class _ParentInfoCard extends StatelessWidget {
  final ParentModel parent;

  const _ParentInfoCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    final details = [
      parent.phone,
      parent.relationshipToStudent,
      parent.address,
    ].where((e) => e != null && e!.trim().isNotEmpty).cast<String>().join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accent.withOpacity(0.18),
            child: const Icon(Icons.person, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.isEmpty ? 'Chưa có thông tin liên hệ' : details,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
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
            child: Text(
              student.fullName.trim().isEmpty ? '?' : student.fullName.trim()[0],
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
