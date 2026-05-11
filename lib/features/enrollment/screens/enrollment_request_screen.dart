import 'package:flutter/material.dart';

import '../repositories/enrollment_request_repository.dart';
import '../../../theme/app_colors.dart';

class EnrollmentRequestScreen extends StatefulWidget {
  const EnrollmentRequestScreen({super.key});

  @override
  State<EnrollmentRequestScreen> createState() => _EnrollmentRequestScreenState();
}

class _EnrollmentRequestScreenState extends State<EnrollmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _parentNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _noteController = TextEditingController();
  final _schoolController = TextEditingController();
  final _gradeController = TextEditingController();
  final _lichessController = TextEditingController();
  final _addressController = TextEditingController();
  final _healthNoteController = TextEditingController();

  final _repository = EnrollmentRequestRepository();

  String _currentLevel = 'Nhập môn';
  String _learningGoal = 'Học cơ bản';
  String _gender = 'Nam';

  bool _isSubmitting = false;

  final _levels = const [
    'Nhập môn',
    'Cơ bản',
    'Tuyển trường',
    'Nâng cao',
    'Chưa xác định',
  ];

  final _goals = const [
    'Học cơ bản',
    'Thi đấu phong trào',
    'Tuyển trường',
    'Học 1-1',
    'Cần tư vấn thêm',
  ];

  final _genders = const ['Nam', 'Nữ'];

  @override
  void dispose() {
    _parentNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _studentNameController.dispose();
    _birthYearController.dispose();
    _noteController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _lichessController.dispose();
    _addressController.dispose();
    _healthNoteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _repository.createEnrollmentRequest(
        parentName: _parentNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        studentName: _studentNameController.text.trim(),
        studentBirthYear: _birthYearController.text.trim(),

        gender: _gender,

        school: _schoolController.text.trim(),
        grade: _gradeController.text.trim(),
        lichessUsername: _lichessController.text.trim(),
        address: _addressController.text.trim(),
        healthNote: _healthNoteController.text.trim(),

        currentLevel: _currentLevel,
        learningGoal: _learningGoal,
        note: _noteController.text.trim(),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            'Đã gửi đăng ký',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Trung tâm đã nhận thông tin. Admin sẽ liên hệ bạn sớm.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đăng ký học')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin phụ huynh', style: _titleStyle),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _parentNameController,
                      decoration: _inputDecoration('Họ tên phụ huynh'),
                      validator: _required('Vui lòng nhập họ tên'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Số điện thoại'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        if (text.length < 9) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email (không bắt buộc)'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Thông tin học sinh', style: _titleStyle),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _studentNameController,
                      decoration: _inputDecoration('Tên học sinh'),
                      validator: _required('Vui lòng nhập tên học sinh'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Năm sinh'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: _inputDecoration('Giới tính'),
                      items: _genders
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _gender = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _schoolController,
                      decoration: _inputDecoration('Trường học'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _gradeController,
                      decoration: _inputDecoration('Lớp'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lichessController,
                      decoration: _inputDecoration('Lichess username'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration('Địa chỉ'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _healthNoteController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: _inputDecoration('Lưu ý sức khỏe'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _currentLevel,
                      decoration: _inputDecoration('Trình độ'),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _currentLevel = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _learningGoal,
                      decoration: _inputDecoration('Mục tiêu học'),
                      items: _goals
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _learningGoal = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _inputDecoration('Ghi chú'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Gửi đăng ký'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _required(String msg) {
    return (value) => (value == null || value.trim().isEmpty) ? msg : null;
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w800,
  fontSize: 16,
);
