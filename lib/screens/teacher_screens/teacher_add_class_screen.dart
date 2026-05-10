import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/class_room_model.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../theme/app_colors.dart';

class TeacherAddClassScreen extends StatefulWidget {
  final ClassRoomModel? existing;

  const TeacherAddClassScreen({super.key, this.existing});

  @override
  State<TeacherAddClassScreen> createState() => _TeacherAddClassScreenState();
}

class _TeacherAddClassScreenState extends State<TeacherAddClassScreen> {
  static final _uuid = Uuid();

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  String _status = 'OPENING';
  String? _selectedTeacherId;
  bool _isSaving = false;
  bool _isAdmin = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _isAdmin = user?.role == 'ADMIN';

    if (_isEdit) {
      final e = widget.existing!;
      _codeCtrl.text = e.classCode;
      _nameCtrl.text = e.className;
      _descCtrl.text = e.description ?? '';
      _levelCtrl.text = e.level ?? '';
      _feeCtrl.text = e.tuitionFee.toStringAsFixed(0);
      _maxCtrl.text = e.maxStudents.toString();
      _roomCtrl.text = e.roomName ?? '';
      _status = e.status;
    }

    Future.microtask(() async {
      final provider = context.read<ClassRoomProvider>();
      await provider.loadTeachers();
      if (_isEdit) {
        _selectedTeacherId = await provider.getAssignedTeacherId(widget.existing!.id);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _levelCtrl.dispose();
    _feeCtrl.dispose();
    _maxCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      _snack('Vui lòng nhập mã lớp và tên lớp');
      return;
    }
    if (_isAdmin && (_selectedTeacherId == null || _selectedTeacherId!.isEmpty)) {
      _snack('Vui lòng gán giáo viên phụ trách cho lớp');
      return;
    }

    final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0;
    final max = int.tryParse(_maxCtrl.text.trim()) ?? 20;

    setState(() => _isSaving = true);

    try {
      if (_isEdit) {
        final updated = ClassRoomModel(
          id: widget.existing!.id,
          classCode: _codeCtrl.text.trim(),
          className: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          level: _levelCtrl.text.trim().isEmpty ? null : _levelCtrl.text.trim(),
          tuitionFee: fee,
          maxStudents: max,
          currentStudents: widget.existing!.currentStudents,
          roomName: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
          status: _status,
          createdAt: widget.existing!.createdAt,
        );
        await context.read<ClassRoomProvider>().updateClassRoom(
              updated,
              teacherId: _isAdmin ? _selectedTeacherId : null,
            );
        if (!mounted) return;
        _snack('Đã cập nhật lớp học');
      } else {
        final newClass = ClassRoomModel(
          id: _uuid.v4(),
          classCode: _codeCtrl.text.trim(),
          className: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          level: _levelCtrl.text.trim().isEmpty ? null : _levelCtrl.text.trim(),
          tuitionFee: fee,
          maxStudents: max,
          currentStudents: 0,
          roomName: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
          status: _status,
          createdAt: DateTime.now().toIso8601String(),
        );
        await context.read<ClassRoomProvider>().addClassRoom(
              newClass,
              teacherId: _isAdmin ? _selectedTeacherId : null,
            );
        if (!mounted) return;
        _snack('Đã thêm lớp học thành công');
      }
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
    final provider = context.watch<ClassRoomProvider>();
    final teachers = provider.teachers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_isEdit ? 'Chỉnh sửa lớp học' : 'Thêm lớp học'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Thông tin lớp'),
            const SizedBox(height: 8),
            _InputField(controller: _codeCtrl, hint: 'Mã lớp *  (vd: CLS004)'),
            const SizedBox(height: 12),
            _InputField(controller: _nameCtrl, hint: 'Tên lớp *'),
            const SizedBox(height: 12),
            _InputField(controller: _descCtrl, hint: 'Mô tả lớp', maxLines: 2),
            const SizedBox(height: 12),
            _InputField(controller: _levelCtrl, hint: 'Trình độ  (vd: Cơ bản, Trung cấp)'),
            const SizedBox(height: 20),
            _SectionLabel('Học phí & sĩ số'),
            const SizedBox(height: 8),
            _InputField(
              controller: _feeCtrl,
              hint: 'Học phí (đ)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _maxCtrl,
              hint: 'Số học sinh tối đa',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Phòng học & trạng thái'),
            const SizedBox(height: 8),
            _InputField(controller: _roomCtrl, hint: 'Phòng học  (vd: Phòng 101)'),
            const SizedBox(height: 12),
            _StatusSelector(
              value: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 20),
              _SectionLabel('Giáo viên phụ trách'),
              const SizedBox(height: 8),
              _TeacherSelector(
                teachers: teachers,
                value: _selectedTeacherId,
                onChanged: (v) => setState(() => _selectedTeacherId = v),
              ),
            ],
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
                    : Text(
                        _isEdit ? 'Cập nhật lớp học' : 'Tạo lớp học',
                        style: const TextStyle(
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('OPENING', 'Đang mở'),
      ('FULL', 'Đã đầy'),
      ('CLOSED', 'Đã đóng'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.card,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: AppColors.textPrimary),
          items: options
              .map((o) => DropdownMenuItem<String>(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}

class _TeacherSelector extends StatelessWidget {
  final List<UserModel> teachers;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TeacherSelector({
    required this.teachers,
    required this.value,
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
        child: DropdownButton<String>(
          value: teachers.any((t) => t.id == value) ? value : null,
          hint: const Text(
            'Chọn giáo viên phụ trách *',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          dropdownColor: AppColors.card,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: AppColors.textPrimary),
          items: teachers
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t.id,
                  child: Text('${t.fullName} • ${t.phone ?? ''}'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
