import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../features/student/providers/student_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/student_model.dart';
import '../../data/models/class_room_model.dart';

class TeacherAddStudentScreen extends StatefulWidget {
  const TeacherAddStudentScreen({super.key});

  @override
  State<TeacherAddStudentScreen> createState() =>
      _TeacherAddStudentScreenState();
}

class _TeacherAddStudentScreenState extends State<TeacherAddStudentScreen> {
  final _nameCtrl = TextEditingController();
  final _parentCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();

  ClassRoomModel? _selectedClassRoom;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ClassRoomProvider>().loadClassRooms();
      final classRooms = context.read<ClassRoomProvider>().classRooms;
      if (classRooms.isNotEmpty && mounted) {
        setState(() {
          _selectedClassRoom = classRooms.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _parentCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classRoomProvider = context.watch<ClassRoomProvider>();
    final classRooms = classRoomProvider.classRooms;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thêm học sinh'),
        centerTitle: true,
      ),
      body: classRoomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InputField(
                    controller: _nameCtrl,
                    hint: 'Tên học sinh',
                  ),
                  const SizedBox(height: 12),

                  _ClassDropdown(
                    classRooms: classRooms,
                    value: _selectedClassRoom,
                    onChanged: (value) {
                      setState(() {
                        _selectedClassRoom = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  _InputField(
                    controller: _parentCtrl,
                    hint: 'Tên phụ huynh',
                  ),
                  const SizedBox(height: 12),

                  _InputField(
                    controller: _phoneCtrl,
                    hint: 'Số điện thoại phụ huynh',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  _InputField(
                    controller: _schoolCtrl,
                    hint: 'Trường học',
                  ),
                  const SizedBox(height: 12),

                  _InputField(
                    controller: _gradeCtrl,
                    hint: 'Khối/Lớp',
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Lưu học sinh',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _parentCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    if (_selectedClassRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lớp học')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final student = StudentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _nameCtrl.text.trim(),
        dateOfBirth: null,
        gender: null,
        school: _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
        grade: _gradeCtrl.text.trim().isEmpty ? null : _gradeCtrl.text.trim(),
        address: null,
        healthNote: _parentCtrl.text.trim(),
        joinDate: DateTime.now().toIso8601String().split('T').first,
        status: 'ACTIVE',
        avatarUrl: null,
        note: _selectedClassRoom!.className,
        createdAt: DateTime.now().toIso8601String(),
      );

      await context.read<StudentProvider>().addStudent(student);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm học sinh thành công')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu học sinh thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ClassDropdown extends StatelessWidget {
  final ClassRoomModel? value;
  final List<ClassRoomModel> classRooms;
  final ValueChanged<ClassRoomModel?> onChanged;

  const _ClassDropdown({
    required this.value,
    required this.classRooms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClassRoomModel>(
          value: value,
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          isExpanded: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
          ),
          hint: const Text(
            'Chọn lớp học',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          items: classRooms
              .map(
                (c) => DropdownMenuItem<ClassRoomModel>(
                  value: c,
                  child: Text(c.className),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}