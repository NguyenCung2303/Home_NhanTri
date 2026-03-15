import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/study_shift_model.dart';
import '../providers/study_shift_provider.dart';

class StudyShiftListScreen extends StatefulWidget {
  const StudyShiftListScreen({super.key});

  @override
  State<StudyShiftListScreen> createState() => _StudyShiftListScreenState();
}

class _StudyShiftListScreenState extends State<StudyShiftListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<StudyShiftProvider>().loadStudyShifts());
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
    final provider = context.watch<StudyShiftProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách ca học'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.shifts.length,
              itemBuilder: (context, index) {
                final shift = provider.shifts[index];
                return ListTile(
                  title: Text(shift.shiftName),
                  subtitle: Text(
                    '${_dayName(shift.dayOfWeek)} • ${shift.startTime} - ${shift.endTime}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteStudyShift(shift.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now().millisecondsSinceEpoch.toString();

          final shift = StudyShiftModel(
            id: now,
            shiftCode: 'SHIFT$now',
            shiftName: 'Ca mới $now',
            dayOfWeek: 1,
            startTime: '18:00',
            endTime: '20:00',
            note: '',
            status: 'ACTIVE',
          );

          await provider.addStudyShift(shift);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}