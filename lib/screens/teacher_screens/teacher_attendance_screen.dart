import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final String className;

  const TeacherAttendanceScreen({
    super.key,
    required this.className,
  });

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final List<Map<String, dynamic>> _students = [
    {'name': 'Nguyễn Văn Minh', 'present': true},
    {'name': 'Trần Thị An', 'present': true},
    {'name': 'Lê Hoàng Long', 'present': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Điểm danh · ${widget.className}'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (_, i) {
          final s = _students[i];
          return _AttendanceItem(
            name: s['name'] as String,
            present: s['present'] as bool,
            onChanged: (v) => setState(() => s['present'] = v),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _showSendNotifyDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Lưu điểm danh',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====== DIALOG XÁC NHẬN ======
  void _showSendNotifyDialog(BuildContext context) {
    final presentCount =
        _students.where((s) => s['present'] == true).length;
    final absentCount = _students.length - presentCount;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            'Gửi thông báo phụ huynh',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Kết quả điểm danh hôm nay:\n\n'
            '- Có mặt: $presentCount học sinh\n'
            '- Vắng: $absentCount học sinh\n\n'
            'Bạn có muốn gửi thông báo không?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Không gửi'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              onPressed: () {
                Navigator.pop(context);
                _sendNotification(context);
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  void _sendNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi thông báo điểm danh đến phụ huynh'),
      ),
    );

    Navigator.pop(context);
  }
}

class _AttendanceItem extends StatelessWidget {
  final String name;
  final bool present;
  final ValueChanged<bool> onChanged;

  const _AttendanceItem({
    required this.name,
    required this.present,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        present ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(
              present ? Icons.check : Icons.close,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: present,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
