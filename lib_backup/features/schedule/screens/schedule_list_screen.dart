import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/schedule_model.dart';
import '../../../data/models/class_room_model.dart';
import '../../../data/models/study_shift_model.dart';
import '../../../features/class_room/providers/class_room_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/study_shift_provider.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ScheduleProvider>().loadSchedules();
      await context.read<ClassRoomProvider>().loadClassRooms();
      await context.read<StudyShiftProvider>().loadStudyShifts();
    });
  }

  String _className(String classId, List<ClassRoomModel> classes) {
    try {
      return classes.firstWhere((e) => e.id == classId).className;
    } catch (_) {
      return 'Không rõ lớp';
    }
  }

  String _shiftName(String shiftId, List<StudyShiftModel> shifts) {
    try {
      final shift = shifts.firstWhere((e) => e.id == shiftId);
      return '${shift.shiftName} (${shift.startTime} - ${shift.endTime})';
    } catch (_) {
      return 'Không rõ ca học';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final classProvider = context.watch<ClassRoomProvider>();
    final shiftProvider = context.watch<StudyShiftProvider>();

    final schedules = scheduleProvider.schedules;
    final classes = classProvider.classRooms;
    final shifts = shiftProvider.shifts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách lịch học'),
      ),
      body: scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : schedules.isEmpty
              ? const Center(child: Text('Chưa có lịch học'))
              : ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final ScheduleModel schedule = schedules[index];
                    return ListTile(
                      title: Text(_className(schedule.classId, classes)),
                      subtitle: Text(
                        '${schedule.studyDate} • ${_shiftName(schedule.shiftId, shifts)} • Phòng: ${schedule.roomName ?? 'Chưa có'} • ${schedule.status}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: () => scheduleProvider.deleteSchedule(schedule.id),
                      ),
                    );
                  },
                ),
    );
  }
}
