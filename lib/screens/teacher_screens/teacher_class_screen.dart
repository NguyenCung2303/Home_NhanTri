import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/class_room_model.dart';
import '../../theme/app_colors.dart';
import 'teacher_add_class_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_class_detail_screen.dart';

class TeacherClassScreen extends StatefulWidget {
  final bool attendanceMode;

  const TeacherClassScreen({super.key, this.attendanceMode = false});

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<ClassRoomProvider>();
    final user = auth.currentUser;
    _isTeacher = user?.role == 'TEACHER';

    if (_isTeacher && user != null) {
      await provider.loadClassRoomsForTeacher(user.id);

      // Tạm fallback để giáo viên vẫn vào được luồng lớp/điểm danh
      // khi dữ liệu phân công giáo viên chưa được migrate đầy đủ sang cloud.
      if (provider.classRooms.isEmpty) {
        await provider.loadClassRooms();
      }
    } else {
      await provider.loadClassRooms();
    }
  }

  String _buildSubInfo(ClassRoomModel c) {
    final room = (c.roomName?.trim().isNotEmpty == true) ? c.roomName! : 'Chưa có phòng';
    final level = (c.level?.trim().isNotEmpty == true) ? c.level! : 'Chưa có trình độ';
    return '$room • $level';
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TeacherAddClassScreen()),
    );
    if (result == true && mounted) {
      context.read<ClassRoomProvider>().loadClassRooms();
    }
  }

  Future<void> _openEdit(ClassRoomModel c) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TeacherAddClassScreen(existing: c)),
    );
    if (result == true && mounted) {
      context.read<ClassRoomProvider>().loadClassRooms();
    }
  }

  Future<void> _confirmDelete(ClassRoomModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xoá lớp học', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Bạn có chắc muốn xoá lớp "${c.className}" không?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ClassRoomProvider>().deleteClassRoom(c.id);
    }
  }

  void _openClassAction(ClassRoomModel c) {
    if (widget.attendanceMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherAttendanceScreen(
            classId: c.id,
            className: c.className,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherClassDetailScreen(
          classId: c.id,
          className: c.className,
          schedule: _buildSubInfo(c),
          count: c.currentStudents,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassRoomProvider>();
    final classRooms = provider.classRooms;
    final showAdminActions = !_isTeacher && !widget.attendanceMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.attendanceMode ? 'Chọn lớp để điểm danh' : 'Lớp phụ trách'),
        centerTitle: true,
        actions: showAdminActions
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Thêm lớp học',
                  onPressed: _openAdd,
                ),
              ]
            : null,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : classRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.class_outlined, size: 56, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        _isTeacher
                            ? 'Bạn chưa được phân công lớp nào'
                            : 'Chưa có lớp học nào',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (showAdminActions) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo lớp học'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classRooms.length,
                  itemBuilder: (context, i) {
                    final c = classRooms[i];
                    return _ClassItem(
                      classRoom: c,
                      subInfo: _buildSubInfo(c),
                      canManage: showAdminActions,
                      actionLabel: widget.attendanceMode ? 'Điểm danh' : 'Chi tiết',
                      onTap: () => _openClassAction(c),
                      onEdit: () => _openEdit(c),
                      onDelete: () => _confirmDelete(c),
                    );
                  },
                ),
    );
  }
}

class _ClassItem extends StatelessWidget {
  final ClassRoomModel classRoom;
  final String subInfo;
  final bool canManage;
  final String actionLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassItem({
    required this.classRoom,
    required this.subInfo,
    required this.canManage,
    required this.actionLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (classRoom.status) {
      case 'OPENING':
        return Colors.green;
      case 'FULL':
        return Colors.blueAccent;
      case 'CLOSED':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _statusText() {
    switch (classRoom.status) {
      case 'OPENING':
        return 'Đang mở';
      case 'FULL':
        return 'Đã đầy';
      case 'CLOSED':
        return 'Đã đóng';
      default:
        return classRoom.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = classRoom;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      c.className,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Mã: ${c.classCode}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(subInfo,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('Học phí: ${c.tuitionFee.toStringAsFixed(0)}đ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${c.currentStudents}/${c.maxStudents} HS',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusText(),
                      style: TextStyle(
                          color: _statusColor(), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onEdit,
                          child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child:
                              const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
