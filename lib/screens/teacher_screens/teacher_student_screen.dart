import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'teacher_add_student_screen.dart';
import '../../theme/app_colors.dart';
import '../../features/student/providers/student_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/student_model.dart';
import '../../data/models/class_room_model.dart';

class TeacherStudentScreen extends StatefulWidget {
  const TeacherStudentScreen({super.key});

  @override
  State<TeacherStudentScreen> createState() => _TeacherStudentScreenState();
}

class _TeacherStudentScreenState extends State<TeacherStudentScreen> {
  ClassRoomModel? _selectedClass; // null = Tất cả
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<StudentProvider>().loadStudents();
      await context.read<ClassRoomProvider>().loadClassRooms();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StudentModel> _filtered(List<StudentModel> all) {
    return all.where((s) {
      final matchName = s.fullName.toLowerCase().contains(_keyword.toLowerCase());
      return matchName;
    }).toList();
  }

  Future<void> _reload() async {
    if (_selectedClass == null) {
      await context.read<StudentProvider>().loadStudents();
    } else {
      await context.read<StudentProvider>().loadStudentsByClass(_selectedClass!.id);
    }
  }

  Future<void> _onClassChanged(ClassRoomModel? c) async {
    setState(() => _selectedClass = c);
    if (c == null) {
      await context.read<StudentProvider>().loadStudents();
    } else {
      await context.read<StudentProvider>().loadStudentsByClass(c.id);
    }
  }

  Future<void> _confirmDelete(StudentModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xoá học sinh', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Xoá "${s.fullName}" khỏi danh sách?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<StudentProvider>().deleteStudent(s.id);
      await context.read<ClassRoomProvider>().loadClassRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final classProvider = context.watch<ClassRoomProvider>();

    final students = _filtered(studentProvider.students);
    final classRooms = classProvider.classRooms;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Quản lý học sinh'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const TeacherAddStudentScreen()),
              );
              if (result == true && mounted) {
                await _reload();
                await context.read<ClassRoomProvider>().loadClassRooms();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _keyword = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm học sinh...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter by class
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  active: _selectedClass == null,
                  onTap: () => _onClassChanged(null),
                ),
                ...classRooms.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: c.className,
                        active: _selectedClass?.id == c.id,
                        onTap: () => _onClassChanged(c),
                      ),
                    )),
              ],
            ),
          ),
          // List
          Expanded(
            child: studentProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const Center(
                        child: Text('Không có học sinh',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: students.length,
                        itemBuilder: (_, i) {
                          final s = students[i];
                          return _StudentItem(
                            student: s,
                            onDelete: () => _confirmDelete(s),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StudentItem extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onDelete;

  const _StudentItem({required this.student, required this.onDelete});

  String get _genderText {
    switch (student.gender) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = student;
    final sub = [
      if (s.school != null && s.school!.isNotEmpty) s.school!,
      if (s.grade != null && s.grade!.isNotEmpty) s.grade!,
      if (_genderText.isNotEmpty) _genderText,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withOpacity(0.2),
            child: Text(
              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                if (s.lichessUsername != null && s.lichessUsername!.isNotEmpty)
                  Text('Lichess: ${s.lichessUsername}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                if (s.joinDate != null)
                  Text('Ngày vào: ${s.joinDate}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: s.status == 'ACTIVE'
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s.status == 'ACTIVE' ? 'Đang học' : 'Nghỉ học',
              style: TextStyle(
                color: s.status == 'ACTIVE' ? Colors.greenAccent : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
