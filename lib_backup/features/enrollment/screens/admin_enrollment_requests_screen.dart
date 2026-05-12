import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/enrollment_request_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../repositories/enrollment_request_repository.dart';
import '../../../data/repositories/class_room_repository.dart';
import '../../../data/models/class_room_model.dart';


class AdminEnrollmentRequestsScreen extends StatefulWidget {
  const AdminEnrollmentRequestsScreen({super.key});

  @override
  State<AdminEnrollmentRequestsScreen> createState() => _AdminEnrollmentRequestsScreenState();
}

class _AdminEnrollmentRequestsScreenState extends State<AdminEnrollmentRequestsScreen> {
  final _repository = EnrollmentRequestRepository();
  final _classRepository = ClassRoomRepository();
  late Future<List<EnrollmentRequestModel>> _future;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAll(status: _filterStatus);
  }

  Future<void> _reload() async {
    final future = _repository.getAll(status: _filterStatus);

    setState(() {
      _future = future;
    });

    await future;
  }

  Future<void> _markContacted(EnrollmentRequestModel item) async {
    await _repository.markContacted(item.id);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chuyển trạng thái sang đã liên hệ')));
  }

  Future<void> _reject(EnrollmentRequestModel item) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Từ chối đơn đăng ký'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Lý do nếu cần'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, reasonController.text), child: const Text('Từ chối')),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    await _repository.reject(item.id, reason: reason);
    await _reload();
  }

  Future<void> _approve(EnrollmentRequestModel item) async {
  final classes = await _classRepository.getAllClassRooms();

  if (!mounted) return;

  if (classes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chưa có lớp học nào để xếp học sinh'),
      ),
    );
    return;
  }

  String selectedClassId = classes.first.id;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Duyệt đăng ký'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Duyệt học sinh ${item.studentName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Chọn lớp học',
                ),
                items: classes.map((classRoom) {
                  return DropdownMenuItem(
                    value: classRoom.id,
                    child: Text(
                      '${classRoom.className} (${classRoom.classCode})',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setDialogState(() {
                    selectedClassId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Duyệt'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed != true) return;

  try {
    await _repository.approveAndCreateAccount(
      requestId: item.id,
      classId: selectedClassId,
    );

    await _reload();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã duyệt và xếp lớp học sinh'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn đăng ký học'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  active: _filterStatus == null,
                  onTap: () {
                    setState(() {
                      _filterStatus = null;
                    });
                    _reload();
                  },
                ),
                _FilterChip(
                  label: 'Chờ xử lý',
                  active: _filterStatus == 'PENDING',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'PENDING';
                    });
                    _reload();
                  },
                ),
                _FilterChip(
                  label: 'Đã liên hệ',
                  active: _filterStatus == 'CONTACTED',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'CONTACTED';
                    });
                    _reload();
                  },
                ),
                _FilterChip(
                  label: 'Đã duyệt',
                  active: _filterStatus == 'APPROVED',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'APPROVED';
                    });
                    _reload();
                  },
                ),
                _FilterChip(
                  label: 'Từ chối',
                  active: _filterStatus == 'REJECTED',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'REJECTED';
                    });
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EnrollmentRequestModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Chưa có đơn đăng ký nào.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, index) => _RequestCard(
                    item: items[index],
                    onContacted: () => _markContacted(items[index]),
                    onApprove: () => _approve(items[index]),
                    onReject: () => _reject(items[index]),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: items.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(label),
        onSelected: (_) => onTap(),
        selectedColor: AppColors.accentSoft,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(color: active ? AppColors.accent : AppColors.textSecondary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final EnrollmentRequestModel item;
  final VoidCallback onContacted;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({required this.item, required this.onContacted, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final canProcess = item.status == 'PENDING' || item.status == 'CONTACTED';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.studentName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              _StatusBadge(status: item.status, text: item.statusText),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.person_rounded, text: 'Phụ huynh: ${item.parentName}'),
          _InfoLine(icon: Icons.phone, text: 'SĐT: ${item.phone}'),
          if ((item.email ?? '').isNotEmpty) _InfoLine(icon: Icons.email, text: 'Email: ${item.email}'),
          if ((item.studentBirthYear ?? '').isNotEmpty) _InfoLine(icon: Icons.cake, text: 'Năm sinh: ${item.studentBirthYear}'),
          if ((item.currentLevel ?? '').isNotEmpty) _InfoLine(icon: Icons.flag, text: 'Trình độ: ${item.currentLevel}'),
          if ((item.learningGoal ?? '').isNotEmpty) _InfoLine(icon: Icons.track_changes, text: 'Nhu cầu: ${item.learningGoal}'),
          if ((item.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.note!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          if ((item.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lý do từ chối: ${item.rejectionReason}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ],
          if (canProcess) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(onPressed: onContacted, icon: const Icon(Icons.call), label: const Text('Đã liên hệ')),
                ElevatedButton.icon(onPressed: onApprove, icon: const Icon(Icons.check_circle_rounded), label: const Text('Duyệt')),
                TextButton.icon(onPressed: onReject, icon: const Icon(Icons.close_rounded), label: const Text('Từ chối')),
              ],
            ),
          ],
          if (item.isApproved) ...[
            const SizedBox(height: 10),
            const Text('Đã tạo tài khoản phụ huynh và hồ sơ học sinh.', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String text;

  const _StatusBadge({required this.status, required this.text});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = AppColors.success;
        break;
      case 'REJECTED':
        color = AppColors.danger;
        break;
      case 'CONTACTED':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.accent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.22))),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
