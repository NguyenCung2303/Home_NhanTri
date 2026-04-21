import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../features/schedule/providers/schedule_provider.dart';
import '../../features/schedule/providers/study_shift_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/study_shift_model.dart';
import '../../data/models/class_room_model.dart';

class TeacherAddScheduleScreen extends StatefulWidget {
  const TeacherAddScheduleScreen({super.key});

  @override
  State<TeacherAddScheduleScreen> createState() =>
      _TeacherAddScheduleScreenState();
}

class _TeacherAddScheduleScreenState extends State<TeacherAddScheduleScreen> {
  ClassRoomModel? _selectedClassRoom;
  StudyShiftModel? _selectedShift;

  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _roomCtrl = TextEditingController();
  final TextEditingController _topicCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<ClassRoomProvider>().loadClassRooms();
      await context.read<StudyShiftProvider>().loadStudyShifts();

      final classRooms = context.read<ClassRoomProvider>().classRooms;
      final shifts = context.read<StudyShiftProvider>().shifts;

      if (mounted) {
        setState(() {
          if (classRooms.isNotEmpty) _selectedClassRoom = classRooms.first;
          if (shifts.isNotEmpty) _selectedShift = shifts.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _roomCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    if (_selectedClassRoom == null || _selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lớp học và ca học')),
      );
      return;
    }

    if (_dateCtrl.text.trim().isEmpty || _roomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ngày học và phòng học')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final schedule = ScheduleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        classId: _selectedClassRoom!.id,
        shiftId: _selectedShift!.id,
        studyDate: _dateCtrl.text.trim(),
        roomName: _roomCtrl.text.trim(),
        lessonTopic: _topicCtrl.text.trim().isEmpty ? null : _topicCtrl.text.trim(),
        note: '',
        status: 'SCHEDULED',
      );

      await context.read<ScheduleProvider>().addSchedule(schedule);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm lịch học')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu lịch học thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classRoomProvider = context.watch<ClassRoomProvider>();
    final shiftProvider = context.watch<StudyShiftProvider>();

    final classRooms = classRoomProvider.classRooms;
    final shifts = shiftProvider.shifts;

    final isLoading = classRoomProvider.isLoading || shiftProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thêm lịch học'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ClassDropdown(
                    value: _selectedClassRoom,
                    classRooms: classRooms,
                    onChanged: (value) {
                      setState(() {
                        _selectedClassRoom = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ShiftDropdown(
                    value: _selectedShift,
                    shifts: shifts,
                    onChanged: (value) {
                      setState(() {
                        _selectedShift = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _dateCtrl,
                    hint: 'Ngày học',
                    readOnly: true,
                    onTap: _pickDate,
                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _roomCtrl,
                    hint: 'Phòng học',
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _topicCtrl,
                    hint: 'Chủ đề buổi học',
                    maxLines: 2,
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
                              'Lưu lịch học',
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
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
          style: const TextStyle(color: AppColors.textPrimary),
          hint: const Text(
            'Chọn lớp học',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          items: classRooms.map((c) {
            return DropdownMenuItem<ClassRoomModel>(
              value: c,
              child: Text('${c.className} (${c.classCode})'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ShiftDropdown extends StatelessWidget {
  final StudyShiftModel? value;
  final List<StudyShiftModel> shifts;
  final ValueChanged<StudyShiftModel?> onChanged;

  const _ShiftDropdown({
    required this.value,
    required this.shifts,
    required this.onChanged,
  });

  String _dayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StudyShiftModel>(
          value: value,
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          isExpanded: true,
          style: const TextStyle(color: AppColors.textPrimary),
          hint: const Text(
            'Chọn ca học',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          items: shifts.map((s) {
            return DropdownMenuItem<StudyShiftModel>(
              value: s,
              child: Text(
                '${s.shiftName} - ${_dayName(s.dayOfWeek)} (${s.startTime} - ${s.endTime})',
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}