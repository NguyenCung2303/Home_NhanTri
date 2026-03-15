import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Điểm danh hôm nay',
      'content': 'Bé Minh có mặt trong buổi học ngày 20/03.',
      'time': '08:45',
      'type': 'attendance',
      'read': false,
    },
    {
      'title': 'Học phí tháng 3',
      'content': 'Học phí tháng 3 đã được cập nhật.',
      'time': '07:30',
      'type': 'tuition',
      'read': true,
    },
    {
      'title': 'Thông báo hệ thống',
      'content': 'Nhà trường nghỉ lễ ngày 30/04.',
      'time': 'Hôm qua',
      'type': 'system',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thông báo'),
        centerTitle: true,
      ),
      body: _notifications.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return _NotificationItem(
                  title: n['title'],
                  content: n['content'],
                  time: n['time'],
                  type: n['type'],
                  read: n['read'],
                  onTap: () {
                    if (!n['read']) {
                      setState(() {
                        n['read'] = true;
                      });
                    }
                  },
                );
              },
            ),
    );
  }
}
class _NotificationItem extends StatelessWidget {
  final String title;
  final String content;
  final String time;
  final String type;
  final bool read;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: read
              ? const Color(0xFF4A4A4A)
              : const Color(0xFF5A5A5A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _iconColor(),
              child: Icon(_iconData(), color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (!read)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE85B7A),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData() {
    switch (type) {
      case 'attendance':
        return Icons.check_circle;
      case 'tuition':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor() {
    switch (type) {
      case 'attendance':
        return Colors.green;
      case 'tuition':
        return Colors.orange;
      default:
        return const Color(0xFFE85B7A);
    }
  }
}
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_off,
              color: Colors.white54, size: 48),
          SizedBox(height: 12),
          Text(
            'Chưa có thông báo',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
