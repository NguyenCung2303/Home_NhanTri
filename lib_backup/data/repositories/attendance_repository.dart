import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/attendance_record_model.dart';
import '../models/student_model.dart';
import '../models/student_tag_model.dart';
import 'student_repository.dart';

class AttendanceSummary {
  final int presentCount;
  final int absentCount;

  const AttendanceSummary({
    required this.presentCount,
    required this.absentCount,
  });

  int get totalSessions => presentCount + absentCount;
}

class AttendanceRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final StudentRepository _studentRepository = StudentRepository();

  Future<List<StudentModel>> getStudentsForClass(String classId) async {
    return _studentRepository.getStudentsByClass(classId);
  }

  Future<List<StudentTagModel>> getActiveStudentTags() async {
    return [];
  }

  Future<List<StudentModel>> getStudentsForTag(String tagId) async {
    return [];
  }

  Future<List<AttendanceRecordModel>> getAttendanceForTagOnDate({
    required String tagId,
    required String attendanceDate,
  }) async {
    return getAttendanceForClassOnDate(
      classId: 'TAG_$tagId',
      attendanceDate: attendanceDate,
    );
  }

  Future<void> saveTagAttendance({
    required String tagId,
    required String attendanceDate,
    required Map<String, bool> studentPresentMap,
  }) async {
    await saveAttendance(
      classId: 'TAG_$tagId',
      attendanceDate: attendanceDate,
      studentPresentMap: studentPresentMap,
      scheduleId: 'TAG_${tagId}_$attendanceDate',
    );
  }

  Future<List<AttendanceRecordModel>> getAttendanceForGroupInMonth({
    required String classId,
    required int year,
    required int month,
  }) async {
    final records = await _getAllAttendanceRecords(pageSize: 500);
    final prefix = '$year-${month.toString().padLeft(2, '0')}';

    return records.where((record) {
      return record.classId == classId &&
          record.attendanceDate.startsWith(prefix);
    }).toList()
      ..sort((a, b) {
        final dateCompare = a.attendanceDate.compareTo(b.attendanceDate);
        if (dateCompare != 0) return dateCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  Future<List<AttendanceRecordModel>> getAttendanceForClassOnDate({
    required String classId,
    required String attendanceDate,
  }) async {
    final records = await _getAllAttendanceRecords(pageSize: 200);

    return records.where((record) {
      return record.classId == classId &&
          record.attendanceDate == attendanceDate;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveAttendance({
    required String classId,
    required String attendanceDate,
    required Map<String, bool> studentPresentMap,
    String? scheduleId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final effectiveScheduleId = scheduleId ?? '${classId}_$attendanceDate';

    final students = await _studentRepository.getStudentsByClass(classId);

    final studentParentMap = {
      for (final student in students) student.id: student.parentUserId ?? '',
    };
    for (final entry in studentPresentMap.entries) {
      final studentId = entry.key;
      final documentId = _safeDocumentId('${effectiveScheduleId}_$studentId');

      final existing = await _getAttendanceDocument(documentId);
      final createdAt = existing?.createdAt ?? now;

      final url = Uri.parse(
        '$_baseUrl/attendance_records/$documentId'
        '?updateMask.fieldPaths=scheduleId'
        '&updateMask.fieldPaths=classId'
        '&updateMask.fieldPaths=studentId'
        '&updateMask.fieldPaths=parentUserId'
        '&updateMask.fieldPaths=attendanceDate'
        '&updateMask.fieldPaths=status'
        '&updateMask.fieldPaths=note'
        '&updateMask.fieldPaths=createdAt'
        '&updateMask.fieldPaths=updatedAt',
      );

      final body = {
        'fields': {
          'scheduleId': {'stringValue': effectiveScheduleId},
          'classId': {'stringValue': classId},
          'studentId': {'stringValue': studentId},
          'parentUserId': {'stringValue': studentParentMap[studentId] ?? ''},
          'attendanceDate': {'stringValue': attendanceDate},
          'status': {'stringValue': entry.value ? 'PRESENT' : 'ABSENT'},
          'note': {'stringValue': existing?.note ?? ''},
          'createdAt': {'timestampValue': createdAt},
          'updatedAt': {'timestampValue': now},
        }
      };

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Không lưu được điểm danh: ${response.body}');
      }
    }
  }

  Future<List<AttendanceRecordModel>> getAttendanceByParentUserId(
    String userId,
  ) async {
    final students = await _studentRepository.getStudentsByParentUserId(userId);
    if (students.isEmpty) return [];

    final studentIds = students.map((student) => student.id).toSet();
    final records = await _getAllAttendanceRecords(pageSize: 500);

    return records
        .where((record) => studentIds.contains(record.studentId))
        .toList()
      ..sort((a, b) {
        final dateCompare = b.attendanceDate.compareTo(a.attendanceDate);
        if (dateCompare != 0) return dateCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<AttendanceSummary> getAttendanceSummaryByParentUserId(
    String userId,
  ) async {
    final records = await getAttendanceByParentUserId(userId);
    final present = records.where((e) => e.status == 'PRESENT').length;
    final absent = records.where((e) => e.status == 'ABSENT').length;

    return AttendanceSummary(
      presentCount: present,
      absentCount: absent,
    );
  }

  Future<List<AttendanceRecordModel>> _getAllAttendanceRecords({
    required int pageSize,
  }) async {
    final url = Uri.parse('$_baseUrl/attendance_records?pageSize=$pageSize');

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được dữ liệu điểm danh: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};

      return AttendanceRecordModel.fromFirestore(id, fields);
    }).toList();
  }

  Future<AttendanceRecordModel?> _getAttendanceDocument(String documentId) async {
    final url = Uri.parse('$_baseUrl/attendance_records/$documentId');

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không kiểm tra được điểm danh cũ: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = data['fields'] as Map<String, dynamic>? ?? {};

    return AttendanceRecordModel.fromFirestore(documentId, fields);
  }

  String _safeDocumentId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_');
  }
}
