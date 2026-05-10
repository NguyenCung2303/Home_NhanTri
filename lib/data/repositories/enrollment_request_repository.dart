import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/enrollment_request_model.dart';
import '../services/database_service.dart';

class EnrollmentApprovalResult {
  final String phone;
  final String password;
  final String parentUserId;
  final String parentId;
  final String studentId;

  const EnrollmentApprovalResult({
    required this.phone,
    required this.password,
    required this.parentUserId,
    required this.parentId,
    required this.studentId,
  });
}

class EnrollmentRequestRepository {
  static final _uuid = Uuid();

  Future<String> createEnrollmentRequest({
    required String parentName,
    required String phone,
    String? email,
    required String studentName,
    String? studentBirthYear,
    String? currentLevel,
    String? learningGoal,
    String? note,
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    await db.insert(
      'enrollment_requests',
      {
        'id': id,
        'parent_name': parentName.trim(),
        'phone': phone.trim(),
        'email': _emptyToNull(email),
        'student_name': studentName.trim(),
        'student_birth_year': _emptyToNull(studentBirthYear),
        'current_level': _emptyToNull(currentLevel),
        'learning_goal': _emptyToNull(learningGoal),
        'note': _emptyToNull(note),
        'status': 'PENDING',
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return id;
  }

  Future<List<EnrollmentRequestModel>> getAll({String? status}) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'enrollment_requests',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: "CASE status WHEN 'PENDING' THEN 0 WHEN 'CONTACTED' THEN 1 WHEN 'APPROVED' THEN 2 ELSE 3 END, created_at DESC",
    );
    return rows.map(EnrollmentRequestModel.fromMap).toList();
  }

  Future<int> countPending() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) AS total FROM enrollment_requests WHERE status IN ('PENDING', 'CONTACTED')");
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> markContacted(String requestId) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'enrollment_requests',
      {
        'status': 'CONTACTED',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status != ?',
      whereArgs: [requestId, 'APPROVED'],
    );
  }

  Future<void> reject(String requestId, {String? reason}) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'enrollment_requests',
      {
        'status': 'REJECTED',
        'rejection_reason': _emptyToNull(reason),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status != ?',
      whereArgs: [requestId, 'APPROVED'],
    );
  }

  Future<EnrollmentApprovalResult> approveAndCreateAccount({
    required String requestId,
    required String approvedBy,
    String relationshipToStudent = 'Phụ huynh',
    String defaultPassword = '123456',
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();

    return db.transaction((txn) async {
      final rows = await txn.query(
        'enrollment_requests',
        where: 'id = ?',
        whereArgs: [requestId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('Không tìm thấy đơn đăng ký');
      }

      final request = EnrollmentRequestModel.fromMap(rows.first);
      if (request.status == 'APPROVED') {
        throw Exception('Đơn này đã được duyệt trước đó');
      }

      final existedUsers = await txn.query(
        'users',
        where: 'phone = ?',
        whereArgs: [request.phone],
        limit: 1,
      );
      if (existedUsers.isNotEmpty) {
        throw Exception('Số điện thoại ${request.phone} đã tồn tại tài khoản. Admin cần kiểm tra trước khi duyệt.');
      }

      final parentUserId = _uuid.v4();
      final parentId = _uuid.v4();
      final studentId = _uuid.v4();
      final linkId = _uuid.v4();

      await txn.insert('users', {
        'id': parentUserId,
        'full_name': request.parentName,
        'phone': request.phone,
        'email': request.email,
        'password_hash': defaultPassword,
        'role': 'PARENT',
        'status': 'ACTIVE',
        'created_at': now,
      });

      await txn.insert('parents', {
        'id': parentId,
        'user_id': parentUserId,
        'full_name': request.parentName,
        'phone': request.phone,
        'email': request.email,
        'address': null,
        'relationship_to_student': relationshipToStudent,
        'note': 'Tạo từ đơn đăng ký học ngày ${_formatDate(now)}',
        'lichess_username': null,
        'created_at': now,
      });

      await txn.insert('students', {
        'id': studentId,
        'full_name': request.studentName,
        'date_of_birth': _birthYearToDate(request.studentBirthYear),
        'gender': null,
        'school': null,
        'grade': null,
        'address': null,
        'health_note': null,
        'join_date': DateTime.now().toIso8601String().substring(0, 10),
        'status': 'ACTIVE',
        'avatar_url': null,
        'note': _buildStudentNote(request),
        'lichess_username': null,
        'created_at': now,
      });

      await txn.insert('parent_student', {
        'id': linkId,
        'parent_id': parentId,
        'student_id': studentId,
        'is_primary_contact': 1,
      });

      await txn.update(
        'enrollment_requests',
        {
          'status': 'APPROVED',
          'approved_at': now,
          'approved_by': approvedBy,
          'parent_user_id': parentUserId,
          'parent_id': parentId,
          'student_id': studentId,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );

      return EnrollmentApprovalResult(
        phone: request.phone,
        password: defaultPassword,
        parentUserId: parentUserId,
        parentId: parentId,
        studentId: studentId,
      );
    });
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _birthYearToDate(String? year) {
    final clean = year?.trim();
    if (clean == null || clean.isEmpty) return null;
    final parsed = int.tryParse(clean);
    if (parsed == null) return null;
    return '$parsed-01-01';
  }

  static String _buildStudentNote(EnrollmentRequestModel request) {
    final parts = <String>[];
    if ((request.currentLevel ?? '').trim().isNotEmpty) {
      parts.add('Trình độ đăng ký: ${request.currentLevel}');
    }
    if ((request.learningGoal ?? '').trim().isNotEmpty) {
      parts.add('Nhu cầu học: ${request.learningGoal}');
    }
    if ((request.note ?? '').trim().isNotEmpty) {
      parts.add('Ghi chú phụ huynh: ${request.note}');
    }
    return parts.isEmpty ? 'Học sinh được tạo từ đơn đăng ký mới.' : parts.join('\n');
  }

  static String _formatDate(String iso) {
    if (iso.length < 10) return iso;
    return iso.substring(0, 10);
  }
}
