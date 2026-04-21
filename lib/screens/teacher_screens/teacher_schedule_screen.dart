import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../features/schedule/providers/schedule_provider.dart';
import '../../features/schedule/providers/study_shift_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/study_shift_model.dart';
import '../../data/models/class_room_model.dart';
import 'teacher_add_schedule_screen.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<ScheduleProvider>().loadSchedules();
      await context.read<StudyShiftProvider>().loadStudyShifts();
      await context.read<ClassRoomProvider>().loadClassRooms();
    });
  }

  String _getClassName(String classId, List<ClassRoomModel> classRooms) {
    try {
      return classRooms.firstWhere((e) => e.id == classId).className;
    } catch (_) {
      return 'Không rõ lớp';
    }
  }

  StudyShiftModel? _getShift(String shiftId, List<StudyShiftModel> shifts) {
    try {
      return shifts.firstWhere((e) => e.id == shiftId);
    } catch (_) {
      return null;
    }
  }

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
    final scheduleProvider = context.watch<ScheduleProvider>();
    final shiftProvider = context.watch<StudyShiftProvider>();
    final classProvider = context.watch<ClassRoomProvider>();

    final schedules = scheduleProvider.schedules;
    final shifts = shiftProvider.shifts;
    final classRooms = classProvider.classRooms;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Lịch học'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherAddScheduleScreen(),
                ),
              );

              if (!mounted) return;
              await context.read<ScheduleProvider>().loadSchedules();
            },
          ),
        ],
      ),
      body: scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : schedules.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có lịch học',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (_, i) {
                    final s = schedules[i];
                    final className = _getClassName(s.classId, classRooms);
                    final shift = _getShift(s.shiftId, shifts);

                    final day = shift != null ? _dayName(shift.dayOfWeek) : 'Không rõ';
                    final time = shift != null
                        ? '${shift.startTime} - ${shift.endTime}'
                        : 'Chưa có ca học';

                    return _ScheduleItem(
                      className: className,
                      room: s.roomName ?? 'Chưa có phòng',
                      time: time,
                      day: day,
                      lessonTopic: s.lessonTopic ?? 'Chưa có chủ đề',
                      studyDate: s.studyDate,
                      status: s.status,
                    );
                  },
                ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String className;
  final String room;
  final String time;
  final String day;
  final String lessonTopic;
  final String studyDate;
  final String status;

  const _ScheduleItem({
    required this.className,
    required this.room,
    required this.time,
    required this.day,
    required this.lessonTopic,
    required this.studyDate,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'SCHEDULED':
      default:
        return Colors.orangeAccent;
    }
  }

  String _statusText() {
    switch (status) {
      case 'COMPLETED':
        return 'Đã học';
      case 'CANCELLED':
        return 'Đã huỷ';
      case 'SCHEDULED':
      default:
        return 'Đã lên lịch';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(Icons.schedule, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$day • $time',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ngày học: $studyDate',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phòng: $room',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lessonTopic,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusText(),
              style: TextStyle(
                color: _statusColor(),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}