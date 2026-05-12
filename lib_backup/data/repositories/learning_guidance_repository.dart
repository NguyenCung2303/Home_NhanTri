import 'dart:convert';

import 'package:http/http.dart' as http;

import 'class_room_repository.dart';
import 'student_repository.dart';

class LearningGuidanceRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final StudentRepository _studentRepository = StudentRepository();
  final ClassRoomRepository _classRoomRepository = ClassRoomRepository();

  Future<String> createGuidance({
    required String teacherId,
    required String classId,
    required String studentId,
    required String strengths,
    required String improvements,
    required String orientation,
    String status = 'DRAFT',
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = _safeDocumentId('${teacherId}_${studentId}_${DateTime.now().millisecondsSinceEpoch}');
    final url = Uri.parse('$_baseUrl/learning_guidance/$id');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'teacherId': {'stringValue': teacherId},
          'classId': {'stringValue': classId},
          'studentId': {'stringValue': studentId},
          'strengths': {'stringValue': strengths},
          'improvements': {'stringValue': improvements},
          'orientation': {'stringValue': orientation},
          'status': {'stringValue': status},
          'sentAt': {'timestampValue': status == 'SENT' ? now : now},
          'createdAt': {'timestampValue': now},
        },
      }),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được định hướng học tập');
    return id;
  }

  Future<void> sendGuidance(String guidanceId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final url = Uri.parse(
      '$_baseUrl/learning_guidance/$guidanceId?updateMask.fieldPaths=status&updateMask.fieldPaths=sentAt',
    );
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'status': {'stringValue': 'SENT'},
          'sentAt': {'timestampValue': now},
        },
      }),
    ).timeout(const Duration(seconds: 15));
    _throwIfFailed(response, 'Không gửi được định hướng');
  }

  Future<List<Map<String, dynamic>>> getRecentByTeacher(String teacherId) async {
    final rows = await _getAllGuidanceRows();
    final students = await _studentRepository.getAllStudents();
    final classes = await _classRoomRepository.getAllClassRooms();

    return rows.where((row) => row['teacher_id'] == teacherId).map((row) {
      final student = students.where((s) => s.id == row['student_id']).cast<dynamic>().toList();
      final classRoom = classes.where((c) => c.id == row['class_id']).cast<dynamic>().toList();
      return {
        ...row,
        'student_name': student.isNotEmpty ? student.first.fullName : '',
        'class_name': classRoom.isNotEmpty ? classRoom.first.className : '',
      };
    }).toList()
      ..sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
  }

  Future<List<Map<String, dynamic>>> getSentByParentUserId(String parentUserId) async {
    final parentStudents = await _studentRepository.getStudentsByParentUserId(parentUserId);
    final ids = parentStudents.map((s) => s.id).toSet();
    final rows = await _getAllGuidanceRows();
    final classes = await _classRoomRepository.getAllClassRooms();

    return rows.where((row) => row['status'] == 'SENT' && ids.contains(row['student_id'])).map((row) {
      final student = parentStudents.where((s) => s.id == row['student_id']).toList();
      final classRoom = classes.where((c) => c.id == row['class_id']).toList();
      return {
        ...row,
        'student_name': student.isNotEmpty ? student.first.fullName : '',
        'class_name': classRoom.isNotEmpty ? classRoom.first.className : '',
        'teacher_name': '',
      };
    }).toList()
      ..sort((a, b) => (b['sent_at'] ?? b['created_at'] ?? '').toString().compareTo((a['sent_at'] ?? a['created_at'] ?? '').toString()));
  }

  Future<List<Map<String, dynamic>>> _getAllGuidanceRows() async {
    final url = Uri.parse('$_baseUrl/learning_guidance?pageSize=500');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được định hướng học tập');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];
    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      String str(String key) {
        final value = fields[key];
        if (value == null) return '';
        return value['stringValue']?.toString() ?? value['timestampValue']?.toString() ?? '';
      }
      return {
        'id': id,
        'teacher_id': str('teacherId'),
        'class_id': str('classId'),
        'student_id': str('studentId'),
        'strengths': str('strengths'),
        'improvements': str('improvements'),
        'orientation': str('orientation'),
        'status': str('status'),
        'sent_at': str('sentAt'),
        'created_at': str('createdAt'),
      };
    }).toList();
  }

  String _safeDocumentId(String value) => value.replaceAll('/', '_').replaceAll(' ', '_').replaceAll(':', '_').replaceAll('.', '_');
  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }
}
