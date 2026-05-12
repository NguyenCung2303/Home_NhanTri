import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/student_model.dart';
import '../providers/student_provider.dart';

class StudentFormScreen extends StatefulWidget {
  final StudentModel? student;

  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _gradeController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _lichessController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  bool get _isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    if (s != null) {
      _fullNameController.text = s.fullName;
      _schoolController.text = s.school ?? '';
      _gradeController.text = s.grade ?? '';
      _genderController.text = s.gender ?? '';
      _dobController.text = s.dateOfBirth ?? '';
      _addressController.text = s.address ?? '';
      _lichessController.text = s.lichessUsername ?? '';
      _noteController.text = s.note ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _lichessController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final old = widget.student;
    final student = StudentModel(
      id: old?.id ?? const Uuid().v4(),
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
      gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
      school: _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
      grade: _gradeController.text.trim().isEmpty ? null : _gradeController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      healthNote: old?.healthNote,
      joinDate: old?.joinDate ?? now.split('T').first,
      status: old?.status ?? 'ACTIVE',
      avatarUrl: old?.avatarUrl,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      lichessUsername: _lichessController.text.trim().isEmpty ? null : _lichessController.text.trim(),
      createdAt: old?.createdAt ?? now,
    );

    if (_isEdit) {
      await context.read<StudentProvider>().updateStudent(student);
    } else {
      await context.read<StudentProvider>().addStudent(student);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa học sinh' : 'Thêm học sinh')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập họ tên học sinh' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lichessController,
              decoration: const InputDecoration(
                labelText: 'Username Lichess',
                hintText: 'Ví dụ: magnuscarlsen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _schoolController, decoration: const InputDecoration(labelText: 'Trường', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _gradeController, decoration: const InputDecoration(labelText: 'Khối/Lớp', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _genderController, decoration: const InputDecoration(labelText: 'Giới tính', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _dobController, decoration: const InputDecoration(labelText: 'Ngày sinh yyyy-MM-dd', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _noteController, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Đang lưu...' : 'Lưu học sinh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
