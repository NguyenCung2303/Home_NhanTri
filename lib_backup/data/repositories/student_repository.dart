import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/student_model.dart';

class StudentRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  Future<List<StudentModel>> getAllStudents() async {
    final docs = await _getAllStudentDocs();
    final students = docs.map((doc) => doc.student).toList();
    return students..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    final students = await getAllStudents();
    return students
        .where((student) => student.classId == classId && student.status == 'ACTIVE')
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<List<StudentModel>> getAvailableStudentsForClass(String classId) async {
    final students = await getAllStudents();
    return students
        .where((student) =>
            student.status == 'ACTIVE' &&
            (student.classId == null || student.classId!.isEmpty))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<void> addStudent(StudentModel student, {String? classId}) async {
    final documentId = student.id.trim().isEmpty
        ? _safeDocumentId('${student.fullName}_${DateTime.now().millisecondsSinceEpoch}')
        : student.id;

    final now = DateTime.now().toUtc().toIso8601String();
    final url = Uri.parse('$_baseUrl/students/$documentId');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': _studentFields(
          student.copyWith(
            id: documentId,
            classId: classId ?? student.classId,
            createdAt: student.createdAt.isNotEmpty ? student.createdAt : now,
          ),
        ),
      }),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không thêm được học sinh');
  }

  Future<void> assignStudentsToClass(String classId, List<String> studentIds) async {
    for (final studentId in studentIds) {
      await _patchStudent(studentId, {
        'classId': {'stringValue': classId},
      }, ['classId']);
    }
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    await _patchStudent(studentId, {
      'classId': {'stringValue': ''},
    }, ['classId']);
  }

  Future<void> updateStudent(StudentModel student) async {
    final url = Uri.parse('$_baseUrl/students/${student.id}');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _studentFields(student)}),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không cập nhật được học sinh');
  }

  Future<void> deleteStudent(String id) async {
    final url = Uri.parse('$_baseUrl/students/$id');
    final response = await http.delete(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return;
    _throwIfFailed(response, 'Không xóa được học sinh');
  }

  Future<List<StudentModel>> getStudentsByParentUserId(String userId) async {
    final docs = await _getAllStudentDocs();
    return docs
        .where((doc) =>
            doc.str('parentUserId') == userId ||
            doc.str('parent_user_id') == userId)
        .map((doc) => doc.student)
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<String?> getClassIdOfStudent(String studentId) async {
    final students = await getAllStudents();
    final student = students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => throw Exception('Không tìm thấy học sinh'),
    );
    return student.classId;
  }

  Future<List<_StudentDoc>> _getAllStudentDocs() async {
    final url = Uri.parse('$_baseUrl/students?pageSize=500');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được danh sách học sinh');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return _StudentDoc(id, fields);
    }).toList();
  }

  Future<void> _patchStudent(
    String studentId,
    Map<String, dynamic> fields,
    List<String> updateMask,
  ) async {
    final mask = updateMask.map((e) => 'updateMask.fieldPaths=$e').join('&');
    final url = Uri.parse('$_baseUrl/students/$studentId?$mask');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': fields}),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không cập nhật được học sinh');
  }

  Map<String, dynamic> _studentFields(StudentModel s) {
    return {
      'fullName': {'stringValue': s.fullName},
      'studentName': {'stringValue': s.fullName},
      'dateOfBirth': {'stringValue': s.dateOfBirth ?? ''},
      'gender': {'stringValue': s.gender ?? ''},
      'school': {'stringValue': s.school ?? ''},
      'grade': {'stringValue': s.grade ?? ''},
      'address': {'stringValue': s.address ?? ''},
      'healthNote': {'stringValue': s.healthNote ?? ''},
      'joinDate': {'stringValue': s.joinDate ?? ''},
      'status': {'stringValue': s.status},
      'avatarUrl': {'stringValue': s.avatarUrl ?? ''},
      'note': {'stringValue': s.note ?? ''},
      'classId': {'stringValue': s.classId ?? ''},
      'parentUserId': {'stringValue': s.parentUserId ?? ''},
      'lichessUsername': {'stringValue': s.lichessUsername ?? ''},
      'createdAt': {'timestampValue': s.createdAt},
    };
  }

  String _safeDocumentId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_');
  }

  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }
}

class _StudentDoc {
  final String id;
  final Map<String, dynamic> fields;

  _StudentDoc(this.id, this.fields);

  StudentModel get student => StudentModel.fromFirestore(id, fields);

  String str(String key) {
    final value = fields[key];
    if (value == null) return '';
    return value['stringValue']?.toString() ??
        value['timestampValue']?.toString() ??
        value['integerValue']?.toString() ??
        value['doubleValue']?.toString() ??
        '';
  }
}
