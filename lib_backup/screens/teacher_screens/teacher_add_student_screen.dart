import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
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
  static final _uuid = Uuid();

  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _lichessCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _gender;
  ClassRoomModel? _selectedClassRoom;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final classProvider = context.read<ClassRoomProvider>();
      final user = auth.currentUser;

      if (user?.role == 'TEACHER' || user?.role == 'ASSISTANT') {
        await classProvider.loadClassRoomsForTeacher(user!.id);
      } else {
        await classProvider.loadClassRooms();
      }

      final classRooms = classProvider.classRooms;
      if (classRooms.isNotEmpty && mounted) {
        setState(() => _selectedClassRoom = classRooms.first);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _schoolCtrl.dispose();
    _gradeCtrl.dispose();
    _addressCtrl.dispose();
    _lichessCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobCtrl.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Vui lòng nhập tên học sinh');
      return;
    }
    if (_selectedClassRoom == null) {
      _snack('Vui lòng chọn lớp học');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final student = StudentModel(
        id: _uuid.v4(),
        fullName: _nameCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        gender: _gender,
        school: _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
        grade: _gradeCtrl.text.trim().isEmpty ? null : _gradeCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        healthNote: null,
        joinDate: DateTime.now().toIso8601String().split('T').first,
        status: 'ACTIVE',
        avatarUrl: null,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        lichessUsername: _lichessCtrl.text.trim().isEmpty ? null : _lichessCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );

      // Truyền classId để ghi đúng vào field classId trên Firestore
      await context.read<StudentProvider>().addStudent(
            student,
            classId: _selectedClassRoom!.id,
          );

      if (!mounted) return;
      _snack('Đã thêm học sinh thành công');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Thông tin học sinh'),
                  const SizedBox(height: 8),
                  _InputField(controller: _nameCtrl, hint: 'Họ và tên *'),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _dobCtrl,
                    hint: 'Ngày sinh (YYYY-MM-DD)',
                    readOnly: true,
                    onTap: _pickDob,
                    suffixIcon: Icons.event_note_rounded,
                  ),
                  const SizedBox(height: 12),
                  _GenderSelector(
                    value: _gender,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),
                  _InputField(controller: _schoolCtrl, hint: 'Trường học'),
                  const SizedBox(height: 12),
                  _InputField(controller: _gradeCtrl, hint: 'Khối/Lớp'),
                  const SizedBox(height: 12),
                  _InputField(controller: _addressCtrl, hint: 'Địa chỉ'),
                  const SizedBox(height: 12),
                  _InputField(controller: _lichessCtrl, hint: 'Username Lichess'),
                  const SizedBox(height: 20),
                  _SectionLabel('Lớp học'),
                  const SizedBox(height: 8),
                  _ClassDropdown(
                    classRooms: classRooms,
                    value: _selectedClassRoom,
                    onChanged: (v) => setState(() => _selectedClassRoom = v),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Ghi chú'),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: _noteCtrl,
                    hint: 'Ghi chú thêm...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GenderSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          dropdownColor: AppColors.card,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: AppColors.textPrimary),
          hint: const Text('Giới tính', style: TextStyle(color: AppColors.textSecondary)),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Nam')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.white54, size: 18)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          style: const TextStyle(color: AppColors.textPrimary),
          hint: const Text('Chọn lớp học', style: TextStyle(color: AppColors.textSecondary)),
          items: classRooms
              .map((c) => DropdownMenuItem<ClassRoomModel>(
                    value: c,
                    child: Text('${c.className} (${c.classCode})'),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
