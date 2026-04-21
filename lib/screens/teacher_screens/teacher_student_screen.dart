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
  String _selectedClass = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  List<StudentModel> _filterStudents(
    List<StudentModel> students,
    List<ClassRoomModel> classRooms,
  ) {
    final filteredByKeyword = students.where((student) {
      final name = student.fullName.toLowerCase();
      return name.contains(_keyword.toLowerCase());
    }).toList();

    if (_selectedClass == 'Tất cả') {
      return filteredByKeyword;
    }

    return filteredByKeyword.where((student) {
      return (student.note ?? '') == _selectedClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final classRoomProvider = context.watch<ClassRoomProvider>();

    final students = studentProvider.students;
    final classRooms = classRoomProvider.classRooms;

    final classNames = <String>[
      'Tất cả',
      ...classRooms.map((e) => e.className),
    ];

    final filtered = _filterStudents(students, classRooms);

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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherAddStudentScreen(),
                ),
              );

              if (!mounted) return;

              context.read<StudentProvider>().loadStudents();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBox(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _keyword = value;
              });
            },
          ),
          _ClassFilter(
            classes: classNames,
            current: _selectedClass,
            onChanged: (v) => setState(() => _selectedClass = v),
          ),
          Expanded(
            child: studentProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có học sinh',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final student = filtered[i];

                          final className =
                              (student.note == null || student.note!.isEmpty)
                                  ? 'Chưa gán lớp'
                                  : student.note!;

                          final parentName =
                              (student.healthNote == null ||
                                      student.healthNote!.isEmpty)
                                  ? 'Chưa có phụ huynh'
                                  : 'Phụ huynh: ${student.healthNote!}';

                          return _StudentItem(
                            student: student,
                            className: className,
                            parent: parentName,
                            onTap: () => _showDetail(
                              context,
                              student: student,
                              className: className,
                              parentName: parentName,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context, {
    required StudentModel student,
    required String className,
    required String parentName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lớp: $className',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                parentName,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Trường: ${student.school ?? 'Chưa có'}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Khối: ${student.grade ?? 'Chưa có'}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Ngày sinh: ${student.dateOfBirth ?? 'Chưa có'}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Xem chi tiết'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm học sinh',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

class _ClassFilter extends StatelessWidget {
  final List<String> classes;
  final String current;
  final ValueChanged<String> onChanged;

  const _ClassFilter({
    required this.classes,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: classes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final item = classes[index];
          final active = item == current;

          return ChoiceChip(
            label: Text(item),
            selected: active,
            onSelected: (_) => onChanged(item),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.card,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}

class _StudentItem extends StatelessWidget {
  final StudentModel student;
  final String className;
  final String parent;
  final VoidCallback onTap;

  const _StudentItem({
    required this.student,
    required this.className,
    required this.parent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final school = student.school ?? 'Chưa có trường';
    final grade = student.grade ?? 'Chưa có khối';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: Colors.white),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$school • $grade',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$className • $parent',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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