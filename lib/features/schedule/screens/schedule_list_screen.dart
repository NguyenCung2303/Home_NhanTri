import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/schedule_model.dart';
import '../providers/schedule_provider.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ScheduleProvider>().loadSchedules());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách lịch học'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.schedules.length,
              itemBuilder: (context, index) {
                final schedule = provider.schedules[index];
                return ListTile(
                  title: Text(schedule.lessonTopic ?? 'Chưa có chủ đề'),
                  subtitle: Text(
                    '${schedule.studyDate} • Phòng: ${schedule.roomName ?? 'Chưa có'} • Trạng thái: ${schedule.status}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteSchedule(schedule.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now().millisecondsSinceEpoch.toString();

          final schedule = ScheduleModel(
            id: now,
            classId: 'demo_class_id',
            shiftId: 'demo_shift_id',
            studyDate: DateTime.now().toIso8601String().split('T').first,
            roomName: 'Phòng A',
            lessonTopic: 'Bài học mới',
            note: '',
            status: 'SCHEDULED',
          );

          await provider.addSchedule(schedule);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}