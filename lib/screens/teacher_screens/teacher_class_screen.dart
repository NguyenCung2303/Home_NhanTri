import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'teacher_class_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/class_room_model.dart';

class TeacherClassScreen extends StatefulWidget {
  const TeacherClassScreen({super.key});

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ClassRoomProvider>().loadClassRooms();
    });
  }

  String _buildSubInfo(ClassRoomModel classRoom) {
    final room = classRoom.roomName?.trim().isNotEmpty == true
        ? classRoom.roomName!
        : 'Chưa có phòng';
    final level = classRoom.level?.trim().isNotEmpty == true
        ? classRoom.level!
        : 'Chưa có trình độ';

    return '$room • $level';
  }

  @override
  Widget build(BuildContext context) {
    final classRoomProvider = context.watch<ClassRoomProvider>();
    final classRooms = classRoomProvider.classRooms;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Lớp học'),
        centerTitle: true,
      ),
      body: classRoomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : classRooms.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có lớp học',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classRooms.length,
                  itemBuilder: (context, index) {
                    final c = classRooms[index];
                    final subInfo = _buildSubInfo(c);

                    return _ClassItem(
                      name: c.className,
                      code: c.classCode,
                      count: c.currentStudents,
                      tuitionFee: c.tuitionFee,
                      subInfo: subInfo,
                      status: c.status,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherClassDetailScreen(
                              className: c.className,
                              schedule: subInfo,
                              count: c.currentStudents,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _ClassItem extends StatelessWidget {
  final String name;
  final String code;
  final int count;
  final double tuitionFee;
  final String subInfo;
  final String status;
  final VoidCallback onTap;

  const _ClassItem({
    required this.name,
    required this.code,
    required this.count,
    required this.tuitionFee,
    required this.subInfo,
    required this.status,
    required this.onTap,
  });

  Color _statusColor() {
    switch (status) {
      case 'OPENING':
        return Colors.green;
      case 'CLOSED':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _statusText() {
    switch (status) {
      case 'OPENING':
        return 'Đang mở';
      case 'CLOSED':
        return 'Đã đóng';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Icon(Icons.class_, color: Colors.white),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã lớp: $code',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subInfo,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Học phí: ${tuitionFee.toStringAsFixed(0)}đ',
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
                  '$count HS',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}