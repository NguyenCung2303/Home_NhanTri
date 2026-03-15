import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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

  String _selectedClass = 'Lớp Mầm 1';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _parentCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thêm học sinh'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InputField(
              controller: _nameCtrl,
              hint: 'Tên học sinh',
            ),
            const SizedBox(height: 12),

            _ClassDropdown(
              value: _selectedClass,
              onChanged: (v) => setState(() => _selectedClass = v),
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

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
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

  void _submit() {
    if (_nameCtrl.text.isEmpty ||
        _parentCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    Navigator.pop(context);
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
        hintStyle:
            const TextStyle(color: AppColors.textSecondary),
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
  final String value;
  final ValueChanged<String> onChanged;

  const _ClassDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final classes = ['Lớp Mầm 1', 'Lớp Chồi 2', 'Lớp Lá 1'];

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
          icon:
              const Icon(Icons.arrow_drop_down, color: Colors.white70),
          isExpanded: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
          ),
          items: classes
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}
