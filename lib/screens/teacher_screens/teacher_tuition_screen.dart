import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../features/tuition/providers/tuition_provider.dart';
import '../../features/student/providers/student_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/tuition_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/class_room_model.dart';

class TeacherTuitionScreen extends StatefulWidget {
  const TeacherTuitionScreen({super.key});

  @override
  State<TeacherTuitionScreen> createState() => _TeacherTuitionScreenState();
}

class _TeacherTuitionScreenState extends State<TeacherTuitionScreen> {
  String _filter = 'Tất cả';

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<TuitionProvider>().loadTuitions();
      await context.read<StudentProvider>().loadStudents();
      await context.read<ClassRoomProvider>().loadClassRooms();
    });
  }

  String _studentName(String id, List<StudentModel> students) {
    try {
      return students.firstWhere((e) => e.id == id).fullName;
    } catch (_) {
      return 'Không rõ';
    }
  }

  String _className(String id, List<ClassRoomModel> classes) {
    try {
      return classes.firstWhere((e) => e.id == id).className;
    } catch (_) {
      return 'Không rõ lớp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tuitionProvider = context.watch<TuitionProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final classProvider = context.watch<ClassRoomProvider>();

    final tuitions = tuitionProvider.tuitions;
    final students = studentProvider.students;
    final classes = classProvider.classRooms;

    final filtered = _filter == 'Tất cả'
        ? tuitions
        : tuitions
            .where((t) =>
                (_filter == 'Đã đóng' && t.status == 'PAID') ||
                (_filter == 'Chưa đóng' && t.status != 'PAID'))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Quản lý học phí'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _FilterBar(
            current: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: tuitionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];

                      final name = _studentName(t.studentId, students);
                      final className = _className(t.classId, classes);

                      final paid = t.status == 'PAID';

                      return _StudentTuitionItem(
                        name: name,
                        className: className,
                        amount: '${t.amount.toStringAsFixed(0)} đ',
                        status: paid ? 'Đã đóng' : 'Chưa đóng',
                        onTap: () => _showDetail(context, t, name, className),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(
      BuildContext context, TuitionModel t, String name, String className) {
    final paid = t.status == 'PAID';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                className,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Học phí: ${t.amount.toStringAsFixed(0)} đ',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hạn đóng: ${t.dueDate}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Trạng thái: ${paid ? "Đã đóng" : "Chưa đóng"}',
                style: TextStyle(
                  color: paid ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 24),
              if (!paid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<TuitionProvider>().markAsPaid(t.id);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Xác nhận đã đóng'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['Tất cả', 'Đã đóng', 'Chưa đóng'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = f == current;

          return InkWell(
            onTap: () => onChanged(f),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudentTuitionItem extends StatelessWidget {
  final String name;
  final String className;
  final String amount;
  final String status;
  final VoidCallback onTap;

  const _StudentTuitionItem({
    required this.name,
    required this.className,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paid = status == 'Đã đóng';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    className,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: paid
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: paid
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}