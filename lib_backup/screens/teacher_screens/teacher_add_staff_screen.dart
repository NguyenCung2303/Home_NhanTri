import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';

class TeacherAddStaffScreen extends StatefulWidget {
  const TeacherAddStaffScreen({super.key});

  @override
  State<TeacherAddStaffScreen> createState() => _TeacherAddStaffScreenState();
}

class _TeacherAddStaffScreenState extends State<TeacherAddStaffScreen> {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: '123456');
  final _salaryCtrl = TextEditingController();

  String _role = 'TEACHER';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final phone = _phoneCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final documentId = _safeDocumentId(
        phone.isNotEmpty ? phone : '${email}_${DateTime.now().millisecondsSinceEpoch}',
      );

      final url = Uri.parse('$_baseUrl/users/$documentId');
      final salary = int.tryParse(_salaryCtrl.text.trim()) ?? 0;

      final body = {
        'fields': {
          'id': {'stringValue': documentId},
          'fullName': {'stringValue': _nameCtrl.text.trim()},
          'phone': {'stringValue': phone},
          'email': {'stringValue': email},
          'passwordHash': {'stringValue': _passwordCtrl.text.trim()},
          'role': {'stringValue': _role},
          'status': {'stringValue': 'ACTIVE'},
          'baseSalary': {'integerValue': salary.toString()},
          'createdAt': {'timestampValue': now},
        }
      };

      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Không tạo được nhân viên: ${response.body}');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thêm nhân viên'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InputField(
              controller: _nameCtrl,
              hint: 'Tên nhân viên',
              icon: Icons.person_rounded,
              validator: _required('Vui lòng nhập tên nhân viên'),
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _phoneCtrl,
              hint: 'Số điện thoại đăng nhập',
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              validator: _required('Vui lòng nhập số điện thoại'),
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _emailCtrl,
              hint: 'Email (không bắt buộc)',
              icon: Icons.email,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _passwordCtrl,
              hint: 'Mật khẩu mặc định',
              icon: Icons.lock_rounded,
              validator: _required('Vui lòng nhập mật khẩu'),
            ),
            const SizedBox(height: 12),
            _RoleDropdown(
              value: _role,
              onChanged: (v) => setState(() => _role = v),
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _salaryCtrl,
              hint: 'Lương cơ bản',
              icon: Icons.payments_rounded,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _isSaving ? null : _saveStaff,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu nhân viên',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String _safeDocumentId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_');
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RoleDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = const [
      {'label': 'Giáo viên', 'value': 'TEACHER'},
      {'label': 'Trợ giảng', 'value': 'ASSISTANT'},
      {'label': 'Quản lý', 'value': 'MANAGER'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: AppColors.card,
                isExpanded: true,
                style: const TextStyle(color: AppColors.textPrimary),
                items: roles
                    .map(
                      (r) => DropdownMenuItem<String>(
                        value: r['value'],
                        child: Text(r['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
