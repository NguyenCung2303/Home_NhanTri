import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../theme/app_colors.dart';
import '../../features/tuition/providers/tuition_provider.dart';
import '../../features/student/providers/student_provider.dart';
import '../../features/class_room/providers/class_room_provider.dart';
import '../../data/models/tuition_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/class_room_model.dart';

class TuitionScreen extends StatefulWidget {
  const TuitionScreen({super.key});

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
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
      return 'Không rõ học sinh';
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

    final isLoading = tuitionProvider.isLoading ||
        studentProvider.isLoading ||
        classProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thanh toán học phí'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tuitions.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có học phí',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tuitions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _BankCard(),
                      );
                    }

                    final tuition = tuitions[index - 1];
                    final studentName = _studentName(tuition.studentId, students);
                    final className = _className(tuition.classId, classes);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TuitionCard(
                        tuition: tuition,
                        studentName: studentName,
                        className: className,
                        onConfirm: () async {
                          await context.read<TuitionProvider>().markAsPaid(tuition.id);

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xác nhận thanh toán'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5AA8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngân hàng VietinBank',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1040 0017 6544 1',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chủ TK: HOME NHÂN TRÍ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance,
              size: 36,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TuitionCard extends StatelessWidget {
  final TuitionModel tuition;
  final String studentName;
  final String className;
  final VoidCallback onConfirm;

  const _TuitionCard({
    required this.tuition,
    required this.studentName,
    required this.className,
    required this.onConfirm,
  });

  String _buildQrContent() {
    final amount = tuition.amount.toStringAsFixed(0);
    final memo = tuition.transactionCode ?? 'HP_${tuition.id}';
    final transactionCode = 'HP_${DateTime.now().millisecondsSinceEpoch}';

    return '''
      BANK: VietinBank
      ACCOUNT: 1040001765441
      ACCOUNT_NAME: HOME NHAN TRI
      AMOUNT: $amount
      MEMO: $memo
      STUDENT: $studentName
      CLASS: $className
      MEMO: $transactionCode
      ''';
        }

  void _showQrDialog(BuildContext context) {
    final qrData = (tuition.qrContent != null && tuition.qrContent!.trim().isNotEmpty)
        ? tuition.qrContent!
        : _buildQrContent();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF4A4A4A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Mã QR thanh toán',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                studentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                className,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Số tiền: ${tuition.amount.toStringAsFixed(0)} ₫',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Nội dung CK: ${tuition.transactionCode ?? 'HP_${tuition.id}'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hạn đóng: ${tuition.dueDate}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paid = tuition.status == 'PAID';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            studentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            className,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${tuition.amount.toStringAsFixed(0)} ₫',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hạn đóng: ${tuition.dueDate}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          if (tuition.note != null && tuition.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tuition.note!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(
                label: paid ? 'Đã thanh toán' : 'Chưa thanh toán',
                color: paid ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _showQrDialog(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xem QR'),
                  ),
                  if (!paid)
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85B7A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Xác nhận'),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}