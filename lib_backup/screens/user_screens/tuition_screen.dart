import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
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
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) return;
      await context.read<TuitionProvider>().loadTuitions(parentUserId: userId);
      await context.read<StudentProvider>().loadStudentsByParentUserId(userId);
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
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _BankCard(),
                  const SizedBox(height: 16),
                  ...students.map((student) {
                    ClassRoomModel? classRoom;

                    try {
                      classRoom = classes.firstWhere(
                        (c) => c.id == student.classId,
                      );
                    } catch (_) {
                      classRoom = null;
                    }

                    final amount = classRoom?.tuitionFee ?? 0;
                    final className = classRoom?.className ?? 'Chưa rõ lớp';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EstimatedTuitionCard(
                        studentName: student.fullName,
                        className: className,
                        amount: amount,
                      ),
                    );
                  }),
                ],
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

                          final userId = context.read<AuthProvider>().currentUser?.id;
                          if (userId != null) {
                            await context.read<TuitionProvider>().loadTuitions(parentUserId: userId);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xác nhận thanh toán')),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngân hàng VietinBank',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  '1040 0017 6544 1',
                  style: TextStyle(color: AppColors.accent, letterSpacing: 1, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Chủ TK: HOME NHÂN TRÍ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance, size: 36, color: Colors.black87),
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

  String _safeMemo() {
    final raw = (tuition.transactionCode != null && tuition.transactionCode!.trim().isNotEmpty)
        ? tuition.transactionCode!.trim()
        : 'HP_${tuition.id}';

    // Nội dung chuyển khoản nên ngắn và không dấu để app ngân hàng đọc ổn định hơn.
    return raw
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toUpperCase();
  }

  String _buildQrContent() {
    final amount = tuition.amount.toStringAsFixed(0);
    final memo = _safeMemo();

    // Fallback QR nội bộ, dùng khi ảnh VietQR không tải được.
    // Giữ text ASCII để qr_flutter không lỗi với một số máy/emulator cũ.
    return 'BANK=VIETINBANK;ACCOUNT=1040001765441;NAME=HOME_NHAN_TRI;AMOUNT=$amount;MEMO=$memo';
  }

  String _buildVietQrImageUrl() {
    final amount = tuition.amount.toStringAsFixed(0);
    final memo = Uri.encodeComponent(_safeMemo());
    final accountName = Uri.encodeComponent('HOME NHAN TRI');

    // VietinBank BIN: 970415. Tài khoản: 1040001765441.
    return 'https://img.vietqr.io/image/970415-1040001765441-compact2.png'
        '?amount=$amount&addInfo=$memo&accountName=$accountName';
  }

  Widget _offlineQrBox(String qrData) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 220,
        gapless: true,
        errorStateBuilder: (context, error) {
          return const SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: Text(
                'Không tạo được QR\nVui lòng chuyển khoản thủ công',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    final qrData = (tuition.qrContent != null && tuition.qrContent!.trim().isNotEmpty)
        ? tuition.qrContent!.trim()
        : _buildQrContent();
    final vietQrUrl = _buildVietQrImageUrl();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Mã QR thanh toán', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  vietQrUrl,
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _offlineQrBox(qrData),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                studentName,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                className,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Số tiền: ${tuition.amount.toStringAsFixed(0)} ₫',
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SelectableText(
                'Nội dung CK: ${_safeMemo()}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = tuition.status == 'PAID';
    final accent = isPaid ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(className, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hạn đóng: ${tuition.dueDate}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Số tiền: ${tuition.amount.toStringAsFixed(0)} ₫',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          if (tuition.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(tuition.note!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPaid ? null : () => _showQrDialog(context),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Xem QR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPaid ? null : onConfirm,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Xác nhận đã chuyển'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
}
class _EstimatedTuitionCard extends StatelessWidget {
  final String studentName;
  final String className;
  final double amount;

  const _EstimatedTuitionCard({
    required this.studentName,
    required this.className,
    required this.amount,
  });

  String _money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Học phí tạm tính',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            studentName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            className,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_money(amount)}đ',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đây là số tiền tạm tính theo học phí của lớp. Hóa đơn chính thức sẽ hiển thị sau khi trung tâm tạo học phí.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}