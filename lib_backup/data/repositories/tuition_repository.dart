import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tuition_model.dart';
import 'class_room_repository.dart';
import 'student_repository.dart';

class TuitionRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final StudentRepository _studentRepository = StudentRepository();
  final ClassRoomRepository _classRoomRepository = ClassRoomRepository();

  Future<List<TuitionModel>> getAllTuitions() async {
    final result = await _getAllTuitionDocuments();
    await _refreshOverdueStatusesFor(result);

    final refreshed = await _getAllTuitionDocuments();

    return refreshed..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<TuitionModel>> getTuitionsByParentUserId(String userId) async {
    final students = await _studentRepository.getStudentsByParentUserId(userId);
    if (students.isEmpty) return [];

    final studentIds = students.map((student) => student.id).toSet();
    final all = await getAllTuitions();

    return all
        .where((tuition) => studentIds.contains(tuition.studentId))
        .toList();
  }

  Future<void> addTuition(TuitionModel tuition) async {
    final fallbackId = _safeDocumentId(
      '${tuition.studentId}_${tuition.classId}_${tuition.tuitionPeriod ?? DateTime.now().millisecondsSinceEpoch}',
    );

    final documentId = tuition.id.trim().isEmpty ? fallbackId : tuition.id;
    final now = DateTime.now().toUtc().toIso8601String();

    final url = Uri.parse('$_baseUrl/tuitions/$documentId');

    final body = {
      'fields': _toFirestoreFields(
        tuition,
        id: documentId,
        createdAt: tuition.createdAt.isNotEmpty ? tuition.createdAt : now,
      ),
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được học phí');
  }

  Future<int> generateMonthlyTuitionsForClass({
    required String classId,
    required String tuitionPeriod,
    required String dueDate,
    String? note,
  }) async {
    final classRoom = await _classRoomRepository.getClassRoomById(classId);
    if (classRoom == null) return 0;

    final students = await _studentRepository.getStudentsByClass(classId);
    if (students.isEmpty) return 0;

    final existing = await _getAllTuitionDocuments();
    final existingKeys = existing
        .map(
          (t) => _tuitionKey(
            studentId: t.studentId,
            classId: t.classId,
            tuitionPeriod: t.tuitionPeriod ?? '',
          ),
        )
        .toSet();

    var created = 0;
    final now = DateTime.now().toUtc().toIso8601String();

    for (final student in students) {
      final key = _tuitionKey(
        studentId: student.id,
        classId: classId,
        tuitionPeriod: tuitionPeriod,
      );

      if (existingKeys.contains(key)) continue;

      final documentId = _safeDocumentId(key);

      final tuition = TuitionModel(
        id: documentId,
        studentId: student.id,
        classId: classId,
        amount: classRoom.tuitionFee,
        dueDate: dueDate,
        paidDate: null,
        status: 'UNPAID',
        paymentMethod: null,
        transactionCode: 'HP_${student.id}_$tuitionPeriod',
        qrContent: null,
        note: note ?? 'Học phí kỳ $tuitionPeriod',
        tuitionPeriod: tuitionPeriod,
        createdAt: now,
      );

      await addTuition(tuition);
      created++;
    }

    return created;
  }

  Future<void> deleteTuition(String id) async {
    final url = Uri.parse('$_baseUrl/tuitions/$id');
    final response = await http.delete(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return;
    _throwIfFailed(response, 'Không xóa được học phí');
  }

  Future<void> markAsPaid(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final url = Uri.parse(
      '$_baseUrl/tuitions/$id'
      '?updateMask.fieldPaths=status'
      '&updateMask.fieldPaths=paidDate'
      '&updateMask.fieldPaths=paymentMethod'
      '&updateMask.fieldPaths=updatedAt',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'status': {'stringValue': 'PAID'},
          'paidDate': {'timestampValue': now},
          'paymentMethod': {'stringValue': 'BANK_TRANSFER'},
          'updatedAt': {'timestampValue': now},
        },
      }),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không xác nhận được học phí');
  }

  Future<void> refreshOverdueStatuses() async {
    final all = await _getAllTuitionDocuments();
    await _refreshOverdueStatusesFor(all);
  }

  Future<void> _refreshOverdueStatusesFor(List<TuitionModel> tuitions) async {
    final today = DateTime.now();
    final todayText = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')
        .first;

    for (final tuition in tuitions) {
      if (tuition.status == 'PAID') continue;
      if (tuition.dueDate.compareTo(todayText) >= 0) continue;

      final url = Uri.parse(
        '$_baseUrl/tuitions/${tuition.id}?updateMask.fieldPaths=status'
        '&updateMask.fieldPaths=updatedAt',
      );

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'status': {'stringValue': 'OVERDUE'},
            'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          },
        }),
      ).timeout(const Duration(seconds: 15));

      _throwIfFailed(response, 'Không cập nhật quá hạn học phí');
    }
  }

  Future<List<TuitionModel>> _getAllTuitionDocuments() async {
    final url = Uri.parse('$_baseUrl/tuitions?pageSize=500');

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được danh sách học phí');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};

      return TuitionModel.fromFirestore(id, fields);
    }).toList();
  }




  Map<String, dynamic> _toFirestoreFields(
    TuitionModel tuition, {
    required String id,
    required String createdAt,
  }) {
    return {
      'id': {'stringValue': id},
      'studentId': {'stringValue': tuition.studentId},
      'classId': {'stringValue': tuition.classId},
      'amount': {'doubleValue': tuition.amount},
      'dueDate': {'stringValue': tuition.dueDate},
      'paidDate': {'stringValue': tuition.paidDate ?? ''},
      'status': {'stringValue': tuition.status},
      'paymentMethod': {'stringValue': tuition.paymentMethod ?? ''},
      'transactionCode': {
        'stringValue': tuition.transactionCode ?? 'HP_$id',
      },
      'qrContent': {'stringValue': tuition.qrContent ?? ''},
      'note': {'stringValue': tuition.note ?? ''},
      'tuitionPeriod': {'stringValue': tuition.tuitionPeriod ?? ''},
      'paidAmount': {'doubleValue': 0},
      'createdAt': {'timestampValue': createdAt},
      'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    };
  }

  String _tuitionKey({
    required String studentId,
    required String classId,
    required String tuitionPeriod,
  }) {
    return '${studentId}_${classId}_$tuitionPeriod';
  }

  String _safeDocumentId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_').replaceAll('@', '_at_');
  }

  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }

  /// Tạo nhanh 1 bill học phí để test màn phụ huynh + QR.
  /// Không dùng hardcode trong UI production.
  Future<void> createTestTuition({
    required String studentId,
    required String parentUserId,
    required String classId,
    required double amount,
    String? tuitionPeriod,
    String? dueDate,
    String? note,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();

    final period =
        tuitionPeriod ?? '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final billDueDate =
        dueDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-05';

    final tuitionId = _safeDocumentId('${studentId}_$period');
    final url = Uri.parse('$_baseUrl/tuitions/$tuitionId');

    final response = await http
        .patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'id': {'stringValue': tuitionId},
              'studentId': {'stringValue': studentId},
              'parentUserId': {'stringValue': parentUserId},
              'classId': {'stringValue': classId},
              'amount': {'doubleValue': amount},
              'paidAmount': {'doubleValue': 0},
              'status': {'stringValue': 'UNPAID'},
              'tuitionPeriod': {'stringValue': period},
              'dueDate': {'stringValue': billDueDate},
              'paidDate': {'stringValue': ''},
              'paymentMethod': {'stringValue': ''},
              'transactionCode': {'stringValue': 'HP_${studentId}_$period'},
              'qrContent': {'stringValue': ''},
              'note': {'stringValue': note ?? 'Học phí test tháng $period'},
              'createdAt': {'timestampValue': nowIso},
              'updatedAt': {'timestampValue': nowIso},
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được học phí test');
  }

}
